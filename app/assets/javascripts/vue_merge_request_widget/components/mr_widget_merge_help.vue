<script>
  import { sprintf, s__ } from '~/locale';

  export default {
    name: 'MRWidgetMergeHelp',
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
          s__('mrWidget|If the %{branch} branch exists in your local repository, you can merge this merge request manually using the'),
          { branch: this.missingBranch },
        );
      },
    },
  };
</script>
<template>
  <section class="mr-widget-help">
    <template v-if="missingBranch">
      {{ missingBranchInfo }}
    </template>
    <template v-else>
      {{ s__("mrWidget|You can merge this merge request manually using the") }}
    </template>

    <button
      type="button"
      class="btn-link btn-blank js-open-modal-help"
      data-toggle="modal"
      data-target="#modal_merge_info"
    >
      {{ s__("mrWidget|command line") }}
    </button>
  </section>
</template>
