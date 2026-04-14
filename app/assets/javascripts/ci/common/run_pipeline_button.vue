<script>
import { GlButton, GlButtonGroup, GlDisclosureDropdown } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

export default {
  name: 'RunPipelineButton',
  components: {
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdown,
  },
  inject: ['newPipelinePath'],
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    variant: {
      type: String,
      required: false,
      default: 'default',
      validator: (variant) => ['default', 'confirm', 'danger', 'link'].includes(variant),
    },
    mergeRequestId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  emits: ['run-pipeline'],
  data() {
    return {};
  },
  computed: {
    showRunWithModifiedValues() {
      return Boolean(this.mergeRequestId);
    },
    newPipelineUrl() {
      return mergeUrlParams({ merge_request_iid: this.mergeRequestId }, this.newPipelinePath);
    },
    dropdownItems() {
      return [
        {
          text: s__('Pipeline|Run pipeline with modified values'),
          href: this.newPipelineUrl,
        },
      ];
    },
  },
};
</script>
<template>
  <gl-button-group>
    <gl-button :variant="variant" :loading="isLoading" @click="$emit('run-pipeline')">
      {{ s__('Pipeline|Run pipeline') }}
    </gl-button>

    <gl-disclosure-dropdown
      v-if="showRunWithModifiedValues"
      :variant="variant"
      placement="bottom-end"
      :aria-label="s__('Pipeline|Run pipeline with modified values')"
      :items="dropdownItems"
    />
  </gl-button-group>
</template>
