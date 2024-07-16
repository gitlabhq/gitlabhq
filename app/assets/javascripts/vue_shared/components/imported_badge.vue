<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

import { TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { TYPE_ACTIVITY, TYPE_COMMENT, TYPE_DESIGN, TYPE_SNIPPET } from '~/import/constants';

const importableTypeText = {
  [TYPE_ACTIVITY]: __('activity'),
  [TYPE_COMMENT]: __('comment'),
  [TYPE_DESIGN]: __('design'),
  [TYPE_EPIC]: __('epic'),
  [TYPE_ISSUE]: __('issue'),
  [TYPE_MERGE_REQUEST]: __('merge request'),
  [TYPE_SNIPPET]: __('snippet'),
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
    textOnly: {
      type: Boolean,
      required: false,
      default: false,
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
  <span v-if="textOnly" v-gl-tooltip="title">
    {{ __('Imported') }}
  </span>
  <gl-badge v-else v-gl-tooltip="title" class="gl-shrink-0">
    {{ __('Imported') }}
  </gl-badge>
</template>
