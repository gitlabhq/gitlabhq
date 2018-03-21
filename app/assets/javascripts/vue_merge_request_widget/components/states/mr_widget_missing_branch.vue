<script>
  import { sprintf, s__ } from '~/locale';
  import tooltip from '~/vue_shared/directives/tooltip';
  import statusIcon from '../mr_widget_status_icon.vue';
  import mrWidgetMergeHelp from '../../components/mr_widget_merge_help.vue';

  export default {
    name: 'MRWidgetMissingBranch',
    directives: {
      tooltip,
    },
    components: {
      mrWidgetMergeHelp,
      statusIcon,
    },
    props: {
      mr: {
        type: Object,
        required: true,
      },
    },
    computed: {
      missingBranchName() {
        return this.mr.sourceBranchRemoved ? 'source' : 'target';
      },
      missingBranchNameMessage() {
        return sprintf(s__('mrWidget| Please restore it or use a different %{missingBranchName} branch'), {
          missingBranchName: this.missingBranchName,
        });
      },
      message() {
        return sprintf(s__('mrWidget|If the %{missingBranchName} branch exists in your local repository, you can merge this merge request manually using the command line'), {
          missingBranchName: this.missingBranchName,
        });
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon
      status="warning"
      :show-disabled-button="true"
    />

    <div class="media-body space-children">
      <span class="bold js-branch-text">
        <span class="capitalize">
          {{ missingBranchName }}
        </span> {{ s__("mrWidget|branch does not exist.") }}
        {{ missingBranchNameMessage }}
        <i
          v-tooltip
          class="fa fa-question-circle"
          :title="message"
          :aria-label="message"
        >
        </i>
      </span>
    </div>
  </div>
</template>
