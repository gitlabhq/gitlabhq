<script>
import { GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
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
    jobName: {
      type: String,
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
  emits: ['select-artifact'],
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
    ariaLabel() {
      return sprintf(
        s__('Artifacts|Select artifacts for %{jobName}'),
        { jobName: this.jobName },
        false,
      );
    },
  },
  methods: {
    handleChange(checked) {
      if (checked) {
        this.unselectedArtifacts.forEach((node) => this.$emit('select-artifact', node, true));
      } else {
        this.selectedArtifacts.forEach((node) => this.$emit('select-artifact', node, false));
      }
    },
  },
};
</script>
<template>
  <gl-form-checkbox
    v-gl-tooltip.right
    :title="tooltipText"
    :aria-label="ariaLabel"
    :disabled="disabled"
    :checked="checked"
    :indeterminate="indeterminate"
    class="gl-w-0"
    @change="handleChange"
  />
</template>
