<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    secureFile: {
      type: Object,
      required: true,
    },
    admin: {
      type: Boolean,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  i18n: {
    metadataLabel: __('View File Metadata'),
  },
  metadataModalId: 'metadataModalId',
  methods: {
    selectSecureFile() {
      this.$emit('selectSecureFile', this.secureFile);
    },
    hasMetadata() {
      return this.secureFile.metadata !== null;
    },
  },
};
</script>

<template>
  <gl-button
    v-if="admin && hasMetadata()"
    v-gl-modal="modalId"
    v-gl-tooltip.hover.top="$options.i18n.metadataLabel"
    category="secondary"
    icon="doc-text"
    :aria-label="$options.i18n.metadataLabel"
    @click="selectSecureFile()"
  />
</template>
