<script>
import { uniqueId } from 'lodash';
import { GlButton, GlTooltipDirective, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import deleteCustomEmojiMutation from '../queries/delete_custom_emoji.mutation.graphql';

export default {
  name: 'DeleteItem',
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    emoji: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDeleting: false,
      modalId: uniqueId('delete-custom-emoji-'),
    };
  },
  methods: {
    showModal() {
      this.$refs['delete-modal'].show();
    },
    async onDelete() {
      this.isDeleting = true;

      try {
        await this.$apollo.mutate({
          mutation: deleteCustomEmojiMutation,
          variables: {
            id: this.emoji.id,
          },
          update: (cache) => {
            const cacheId = cache.identify(this.emoji);
            cache.evict({ id: cacheId });
          },
        });
      } catch (e) {
        createAlert(__('Failed to delete custom emoji. Please try again.'));
        Sentry.captureException(e);
      }
    },
  },
  actionPrimary: { text: __('Delete'), attributes: { variant: 'danger' } },
  actionSecondary: { text: __('Cancel'), attributes: { variant: 'default' } },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip
      icon="remove"
      :aria-label="__('Delete custom emoji')"
      :title="__('Delete custom emoji')"
      :loading="isDeleting"
      data-testid="delete-button"
      @click="showModal"
    />
    <gl-modal
      ref="delete-modal"
      :title="__('Delete custom emoji')"
      :action-primary="$options.actionPrimary"
      :action-secondary="$options.actionSecondary"
      :modal-id="modalId"
      size="sm"
      @primary="onDelete"
    >
      <gl-sprintf
        :message="__('Are you sure you want to delete %{name}? This action cannot be undone.')"
      >
        <template #name
          ><strong>{{ emoji.name }}</strong></template
        >
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
