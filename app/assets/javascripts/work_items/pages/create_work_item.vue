<script>
import { GlButton, GlAlert } from '@gitlab/ui';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';

import ItemTitle from '../components/item_title.vue';

export default {
  components: {
    GlButton,
    GlAlert,
    ItemTitle,
  },
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      title: this.initialTitle,
      error: false,
    };
  },
  methods: {
    async createWorkItem() {
      try {
        const response = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.title,
            },
          },
        });

        const {
          data: {
            localCreateWorkItem: {
              workItem: { id },
            },
          },
        } = response;
        if (!this.isModal) {
          this.$router.push({ name: 'workItem', params: { id } });
        } else {
          this.$emit('onCreate', this.title);
        }
      } catch {
        this.error = true;
      }
    },
    handleTitleInput(title) {
      this.title = title;
    },
    handleCancelClick() {
      if (!this.isModal) {
        this.$router.go(-1);
        return;
      }
      this.$emit('closeModal');
    },
  },
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">{{
      __('Something went wrong when creating a work item. Please try again')
    }}</gl-alert>
    <item-title :initial-title="title" data-testid="title-input" @title-input="handleTitleInput" />
    <div
      class="gl-bg-gray-10 gl-py-5 gl-px-6"
      :class="{ 'gl-display-flex gl-justify-content-end': isModal }"
    >
      <gl-button
        variant="confirm"
        :disabled="title.length === 0"
        :class="{ 'gl-mr-3': !isModal }"
        data-testid="create-button"
        type="submit"
      >
        {{ s__('WorkItem|Create work item') }}
      </gl-button>
      <gl-button
        type="button"
        data-testid="cancel-button"
        class="gl-order-n1"
        :class="{ 'gl-mr-3': isModal }"
        @click="handleCancelClick"
      >
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
