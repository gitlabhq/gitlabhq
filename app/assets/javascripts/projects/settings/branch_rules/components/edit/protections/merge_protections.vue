<script>
import { GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { s__ } from '~/locale';

export const i18n = {
  allowedToMerge: s__('BranchRules|Allowed to merge'),
  requireApprovalTitle: s__('BranchRules|Require approval from code owners.'),
  requireApprovalHelpText: s__(
    'BranchRules|Reject code pushes that change files listed in the CODEOWNERS file.',
  ),
};

export default {
  name: 'BranchMergeProtections',
  i18n,
  components: {
    GlFormGroup,
    GlFormCheckbox,
  },
  props: {
    membersAllowedToMerge: {
      type: Array,
      required: true,
    },
    requireCodeOwnersApproval: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.allowedToMerge">
    <!-- TODO: add multi-select-dropdown (https://gitlab.com/gitlab-org/gitlab/-/issues/362212) -->

    <gl-form-checkbox
      class="gl-mt-5"
      :checked="requireCodeOwnersApproval"
      @change="$emit('change-require-code-owners-approval', $event)"
    >
      <span>{{ $options.i18n.requireApprovalTitle }}</span>
      <template #help>{{ $options.i18n.requireApprovalHelpText }}</template>
    </gl-form-checkbox>
  </gl-form-group>
</template>
