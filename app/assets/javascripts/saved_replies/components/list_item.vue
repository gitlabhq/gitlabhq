<script>
import { uniqueId } from 'lodash';
import { GlDisclosureDropdown, GlTooltip, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import deleteSavedReplyMutation from '../queries/delete_saved_reply.mutation.graphql';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
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
      toggleId: uniqueId('actions-toggle-'),
    };
  },
  computed: {
    id() {
      return getIdFromGraphQLId(this.reply.id);
    },
    dropdownItems() {
      return [
        {
          text: __('Edit'),
          action: () => this.$router.push({ name: 'edit', params: { id: this.id } }),
          extraAttrs: {
            'data-testid': 'saved-reply-edit-btn',
          },
        },
        {
          text: __('Delete'),
          action: () => this.$refs['delete-modal'].show(),
          extraAttrs: {
            'data-testid': 'saved-reply-delete-btn',
            class: 'gl-text-red-500!',
          },
        },
      ];
    },
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
  <li class="gl-pt-4 gl-pb-5 gl-border-b">
    <div class="gl-display-flex gl-align-items-center">
      <h6 class="gl-mr-3 gl-my-0" data-testid="saved-reply-name">{{ reply.name }}</h6>
      <div class="gl-ml-auto">
        <gl-disclosure-dropdown
          :items="dropdownItems"
          :toggle-id="toggleId"
          icon="ellipsis_v"
          no-caret
          text-sr-only
          placement="right"
          :toggle-text="__('Saved reply actions')"
          :loading="isDeleting"
          category="tertiary"
        />
        <gl-tooltip :target="toggleId">
          {{ __('Saved reply actions') }}
        </gl-tooltip>
      </div>
    </div>
    <div class="gl-mt-3 gl-font-monospace">{{ reply.content }}</div>
    <gl-modal
      ref="delete-modal"
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
