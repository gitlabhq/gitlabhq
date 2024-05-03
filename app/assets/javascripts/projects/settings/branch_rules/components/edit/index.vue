<script>
import { GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import BranchDropdown from './branch_dropdown.vue';
import Protections from './protections/index.vue';

export default {
  name: 'RuleEdit',
  i18n: { branch: s__('BranchRules|Branch') },
  components: {
    BranchDropdown,
    GlFormGroup,
    Protections,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      branch: getParameterByName('branch'),
      protections: {
        membersAllowedToPush: [],
        allowForcePush: false,
        membersAllowedToMerge: [],
        requireCodeOwnersApproval: false,
      },
    };
  },
};
</script>

<template>
  <div>
    <gl-form-group :label="$options.i18n.branch">
      <branch-dropdown
        id="branches"
        v-model="branch"
        class="gl-w-1/2"
        :project-path="projectPath"
        @createWildcard="branch = $event"
      />
    </gl-form-group>

    <protections
      :protections="protections"
      @change-allowed-to-push-members="protections.membersAllowedToPush = $event"
      @change-allow-force-push="protections.allowForcePush = $event"
      @change-allowed-to-merge-members="protections.membersAllowedToMerge = $event"
      @change-require-code-owners-approval="protections.requireCodeOwnersApproval = $event"
    />
  </div>
</template>
