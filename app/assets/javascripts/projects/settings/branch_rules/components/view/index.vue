<script>
import { s__ } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';

export default {
  name: 'RuleView',
  i18n: { branch: s__('BranchRules|Target Branch') },
  components: {},
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      branch: getParameterByName('branch'),
      protected: getParameterByName('protected'),
    };
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-flex-direction-column gl-pt-3">
      <strong>{{ $options.i18n.branch }}</strong>
      <span class="gl-font-monospace gl-mt-2" data-testid="branch">{{ branch }}</span>
    </div>

    <!-- TODO: List branch rule details (https://gitlab.com/gitlab-org/gitlab/-/issues/372362) -->
  </div>
</template>
