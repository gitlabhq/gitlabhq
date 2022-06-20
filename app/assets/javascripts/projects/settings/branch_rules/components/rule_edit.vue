<script>
import { GlFormGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import BranchDropdown from './branch_dropdown.vue';

export default {
  name: 'RuleEdit',
  i18n: {
    branch: __('Branch'),
  },
  components: { BranchDropdown, GlFormGroup },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      branch: getParameterByName('branch'),
    };
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.branch">
    <branch-dropdown
      id="branches"
      v-model="branch"
      class="gl-w-half"
      :project-path="projectPath"
      @createWildcard="branch = $event"
    />
  </gl-form-group>
  <!-- TODO - Add branch protections (https://gitlab.com/gitlab-org/gitlab/-/issues/362212) -->
</template>
