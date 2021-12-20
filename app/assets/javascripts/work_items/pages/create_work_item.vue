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
  data() {
    return {
      title: '',
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
        this.$router.push({ name: 'workItem', params: { id } });
      } catch {
        this.error = true;
      }
    },
    handleTitleInput(title) {
      this.title = title;
    },
  },
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">{{
      __('Something went wrong when creating a work item. Please try again')
    }}</gl-alert>
    <item-title data-testid="title-input" @title-input="handleTitleInput" />
    <div class="gl-bg-gray-10 gl-py-5 gl-px-6">
      <gl-button
        variant="confirm"
        :disabled="title.length === 0"
        class="gl-mr-3"
        data-testid="create-button"
        type="submit"
      >
        {{ __('Create') }}
      </gl-button>
      <gl-button type="button" data-testid="cancel-button" @click="$router.go(-1)">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
