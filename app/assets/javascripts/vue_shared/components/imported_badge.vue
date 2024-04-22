<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

import { TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';

const importableTypeText = {
  [TYPE_EPIC]: __('epic'),
  [TYPE_ISSUE]: __('issue'),
  [TYPE_MERGE_REQUEST]: __('merge request'),
};

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    importableType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    title() {
      return sprintf(s__('BulkImport|This %{importable} was imported from another instance.'), {
        importable: importableTypeText[this.importableType],
      });
    },
  },
};
</script>

<template>
  <gl-badge v-gl-tooltip="title">
    {{ __('Imported') }}
  </gl-badge>
</template>
