<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub, { EVENT_OPEN_DELETE_LABEL_MODAL } from '../event_hub';

export default {
  name: 'LabelActions',
  components: {
    GlDisclosureDropdown,
  },

  props: {
    labelId: {
      type: String,
      required: true,
    },
    labelName: {
      type: String,
      required: true,
    },
    editPath: {
      type: String,
      required: true,
    },
    destroyPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    items() {
      return [
        {
          text: __('Edit'),
          href: this.editPath,
        },
        {
          text: __('Delete'),
          action: this.onDelete,
          extraAttrs: {
            class: 'gl-text-red-500!',
            'data-testid': `delete-label-action`,
          },
        },
      ];
    },
  },
  methods: {
    onDelete() {
      eventHub.$emit(EVENT_OPEN_DELETE_LABEL_MODAL, {
        labelId: this.labelId,
        labelName: this.labelName,
        destroyPath: this.destroyPath,
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :title="__('Label actions')"
    :aria-label="__('Label actions dropdown')"
    toggle-class="btn-sm"
    icon="ellipsis_v"
    category="tertiary"
    data-testid="label-actions-dropdown-toggle"
    no-caret
    :items="items"
  />
</template>
