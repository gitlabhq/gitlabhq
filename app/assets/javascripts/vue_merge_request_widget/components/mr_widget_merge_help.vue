<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'MRWidgetMergeHelp',
  components: {
    GlButton,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    missingBranch: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    missingBranchInfo() {
      return sprintf(
        s__(
          'mrWidget|If the %{branch} branch exists in your local repository, you can merge this merge request manually using the',
        ),
        { branch: this.missingBranch },
      );
    },
  },
};
</script>
<template>
  <section class="mr-widget-help font-italic">
    <template v-if="missingBranch">
      {{ missingBranchInfo }}
    </template>
    <template v-else>
      {{ s__('mrWidget|You can merge this merge request manually using the') }}
    </template>

    <gl-button
      v-gl-modal-directive="'modal-merge-info'"
      variant="link"
      class="gl-mt-n2 js-open-modal-help"
    >
      {{ s__('mrWidget|command line') }}
    </gl-button>
  </section>
</template>
