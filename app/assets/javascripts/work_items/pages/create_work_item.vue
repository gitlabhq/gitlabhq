<script>
import { GlButton, GlAlert } from '@gitlab/ui';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';

export default {
  components: {
    GlButton,
    GlAlert,
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
            createWorkItem: {
              workItem: { id },
            },
          },
        } = response;
        this.$router.push({ name: 'workItem', params: { id } });
      } catch {
        this.error = true;
      }
    },
  },
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <gl-alert v-if="error" variant="danger" @dismiss="error = false">{{
      __('Something went wrong when creating a work item. Please try again')
    }}</gl-alert>
    <label for="title" class="gl-sr-only">{{ __('Title') }}</label>
    <input
      id="title"
      v-model.trim="title"
      type="text"
      class="gl-font-size-h-display gl-font-weight-bold gl-my-5 gl-border-none gl-w-full gl-pl-2"
      data-testid="title-input"
      :placeholder="__('Add a title…')"
    />
    <div class="gl-bg-gray-10 gl-py-5 gl-px-6">
      <gl-button
        variant="confirm"
        :disabled="title.length === 0"
        class="gl-mr-3"
        data-testid="create-button"
        type="submit"
        @click="createWorkItem"
      >
        {{ __('Create') }}
      </gl-button>
      <gl-button data-testid="cancel-button" @click="$router.go(-1)">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
