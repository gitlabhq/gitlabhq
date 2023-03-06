<script>
import { uniqueId } from 'lodash';
import { GlButton, GlModal, GlModalDirective, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import deleteSavedReplyMutation from '../queries/delete_saved_reply.mutation.graphql';

export default {
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    reply: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDeleting: false,
      modalId: uniqueId('delete-saved-reply-'),
    };
  },
  methods: {
    onDelete() {
      this.isDeleting = true;

      this.$apollo.mutate({
        mutation: deleteSavedReplyMutation,
        variables: {
          id: this.reply.id,
        },
        update: (cache) => {
          const cacheId = cache.identify(this.reply);
          cache.evict({ id: cacheId });
        },
      });
    },
  },
  actionPrimary: { text: __('Delete'), attributes: { variant: 'danger' } },
  actionSecondary: { text: __('Cancel'), attributes: { variant: 'default' } },
};
</script>

<template>
  <li class="gl-mb-5">
    <div class="gl-display-flex gl-align-items-center">
      <strong>{{ reply.name }}</strong>
      <div class="gl-ml-auto">
        <gl-button
          v-gl-modal="modalId"
          v-gl-tooltip
          icon="remove"
          :aria-label="__('Delete')"
          :title="__('Delete')"
          variant="danger"
          category="secondary"
          data-testid="saved-reply-delete-btn"
          :loading="isDeleting"
        />
      </div>
    </div>
    <div class="gl-mt-3 gl-font-monospace">{{ reply.content }}</div>
    <gl-modal
      :title="__('Delete saved reply')"
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
          ><strong>{{ reply.name }}</strong></template
        >
      </gl-sprintf>
    </gl-modal>
  </li>
</template>
