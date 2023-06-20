<script>
import { GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { I18N_BULK_DELETE_MAX_SELECTED } from '~/ci/artifacts/constants';

export default {
  name: 'JobCheckbox',
  components: {
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    hasArtifacts: {
      type: Boolean,
      required: true,
    },
    selectedArtifacts: {
      type: Array,
      required: true,
    },
    unselectedArtifacts: {
      type: Array,
      required: true,
    },
    isSelectedArtifactsLimitReached: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    disabled() {
      return (
        !this.hasArtifacts ||
        (this.isSelectedArtifactsLimitReached && !(this.checked || this.indeterminate))
      );
    },
    checked() {
      return this.hasArtifacts && this.unselectedArtifacts.length === 0;
    },
    indeterminate() {
      return this.selectedArtifacts.length > 0 && this.unselectedArtifacts.length > 0;
    },
    tooltipText() {
      return this.isSelectedArtifactsLimitReached && this.disabled
        ? I18N_BULK_DELETE_MAX_SELECTED
        : '';
    },
  },
  methods: {
    handleChange(checked) {
      if (checked) {
        this.unselectedArtifacts.forEach((node) => this.$emit('selectArtifact', node, true));
      } else {
        this.selectedArtifacts.forEach((node) => this.$emit('selectArtifact', node, false));
      }
    },
  },
};
</script>
<template>
  <gl-form-checkbox
    v-gl-tooltip.right
    :title="tooltipText"
    :disabled="disabled"
    :checked="checked"
    :indeterminate="indeterminate"
    @change="handleChange"
  />
</template>
