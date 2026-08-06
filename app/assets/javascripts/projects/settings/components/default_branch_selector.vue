<script>
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES } from '~/vue_shared/components/ref/constants';
import { __ } from '~/locale';

export default {
  name: 'DefaultBranchSelector',
  components: {
    RefSelector,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    persistedDefaultBranch: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
  },
  refTypes: [REF_TYPE_BRANCHES],
  i18n: {
    dropdownHeader: __('Select default branch'),
    searchPlaceholder: __('Search branch'),
  },
};
</script>
<template>
  <ref-selector
    :disabled="disabled"
    :value="persistedDefaultBranch"
    class="gl-w-full"
    :project-id="projectId"
    :enabled-ref-types="$options.refTypes"
    :translations="$options.i18n"
    name="project[default_branch]"
    data-testid="default-branch-dropdown"
  />
</template>
