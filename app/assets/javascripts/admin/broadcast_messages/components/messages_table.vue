<script>
import { GlBroadcastMessage, GlButton, GlTableLite } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';

const DEFAULT_TD_CLASSES = 'gl-vertical-align-middle!';

export default {
  name: 'MessagesTable',
  components: {
    GlBroadcastMessage,
    GlButton,
    GlTableLite,
  },
  directives: {
    SafeHtml,
  },
  i18n: {
    edit: __('Edit'),
    delete: __('Delete'),
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
      tdClass: `${DEFAULT_TD_CLASSES} gl-white-space-nowrap`,
    },
  ],
  methods: {
    formatDate(dateString) {
      return formatDate(new Date(dateString));
    },
  },
};
</script>
<template>
  <gl-table-lite
    :items="messages"
    :fields="$options.fields"
    :tbody-tr-attr="{ 'data-testid': 'message-row' }"
    stacked="md"
  >
    <template #cell(preview)="{ item: { message, theme, broadcast_type, dismissable } }">
      <gl-broadcast-message :theme="theme" :type="broadcast_type" :dismissible="dismissable">
        {{ message }}
      </gl-broadcast-message>
    </template>

    <template #cell(starts_at)="{ item: { starts_at } }">
      {{ formatDate(starts_at) }}
    </template>

    <template #cell(ends_at)="{ item: { ends_at } }">
      {{ formatDate(ends_at) }}
    </template>

    <template #cell(buttons)="{ item: { id, edit_path, disable_delete } }">
      <gl-button
        icon="pencil"
        :aria-label="$options.i18n.edit"
        :href="edit_path"
        data-testid="edit-message"
      />

      <gl-button
        class="gl-ml-3"
        icon="remove"
        variant="danger"
        :aria-label="$options.i18n.delete"
        rel="nofollow"
        :disabled="disable_delete"
        :data-testid="`delete-message-${id}`"
        @click="$emit('delete-message', id)"
      />
    </template>
  </gl-table-lite>
</template>
