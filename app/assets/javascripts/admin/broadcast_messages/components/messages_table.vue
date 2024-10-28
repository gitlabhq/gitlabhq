<script>
import { GlBroadcastMessage, GlButton, GlTableLite, GlModal, GlModalDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, s__ } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

const DEFAULT_TD_CLASSES = '!gl-align-baseline';

export default {
  name: 'MessagesTable',
  components: {
    GlBroadcastMessage,
    GlButton,
    GlTableLite,
    GlModal,
  },
  directives: {
    SafeHtml,
    GlModal: GlModalDirective,
  },
  i18n: {
    title: s__('BroadcastMessages|Delete broadcast message'),
    edit: __('Edit'),
    delete: __('Delete'),
    modalMessage: s__('BroadcastMessages|Do you really want to delete this broadcast message?'),
  },
  modal: {
    actionPrimary: {
      text: s__('BroadcastMessages|Delete message'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  props: {
    messages: {
      type: Array,
      required: true,
    },
  },
  fields: [
    {
      key: 'status',
      label: __('Status'),
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'preview',
      label: __('Preview'),
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'starts_at',
      label: __('Starts'),
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'ends_at',
      label: __('Ends'),
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'target_roles',
      label: __('Target roles'),
      tdClass: DEFAULT_TD_CLASSES,
      thAttr: { 'data-testid': 'target-roles-th' },
    },
    {
      key: 'target_path',
      label: __('Target Path'),
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'type',
      label: __('Type'),
      tdClass: DEFAULT_TD_CLASSES,
    },
    {
      key: 'buttons',
      label: '',
      tdClass: `${DEFAULT_TD_CLASSES} gl-whitespace-nowrap`,
    },
  ],
  methods: {
    formatDate(dateString) {
      return localeDateFormat.asDateTimeFull.format(new Date(dateString));
    },
  },
};
</script>
<template>
  <gl-table-lite
    :items="messages"
    :fields="$options.fields"
    :tbody-tr-attr="{ 'data-testid': 'message-row' }"
    class="-gl-mb-2 -gl-mt-1"
    stacked="md"
  >
    <template #cell(preview)="{ item: { message, theme, broadcast_type, dismissable } }">
      <gl-broadcast-message :theme="theme" :type="broadcast_type" :dismissible="dismissable">
        <span v-safe-html="message"></span>
      </gl-broadcast-message>
    </template>

    <template #cell(starts_at)="{ item: { starts_at } }">
      {{ formatDate(starts_at) }}
    </template>

    <template #cell(ends_at)="{ item: { ends_at } }">
      {{ formatDate(ends_at) }}
    </template>

    <template #cell(buttons)="{ item: { id, edit_path, disable_delete } }">
      <div class="gl-flex gl-gap-2">
        <gl-button
          category="tertiary"
          icon="pencil"
          :aria-label="$options.i18n.edit"
          :href="edit_path"
          data-testid="edit-message"
        />
        <gl-button
          v-gl-modal="`delete-message-${id}`"
          category="tertiary"
          icon="remove"
          :aria-label="$options.i18n.delete"
          rel="nofollow"
          :disabled="disable_delete"
          :data-testid="`delete-message-${id}`"
        />
      </div>
      <gl-modal
        :title="$options.i18n.title"
        :action-primary="$options.modal.actionPrimary"
        :action-secondary="$options.modal.actionSecondary"
        :modal-id="`delete-message-${id}`"
        size="sm"
        @primary="$emit('delete-message', id)"
      >
        {{ $options.i18n.modalMessage }}
      </gl-modal>
    </template>
  </gl-table-lite>
</template>
