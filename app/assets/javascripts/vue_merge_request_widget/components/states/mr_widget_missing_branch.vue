<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import missingBranchQuery from '../../queries/states/missing_branch.query.graphql';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetMissingBranch',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    statusIcon,
  },
  mixins: [glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  apollo: {
    state: {
      query: missingBranchQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest,
    },
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { state: {} };
  },
  computed: {
    sourceBranchRemoved() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return !this.state.sourceBranchExists;
      }

      return this.mr.sourceBranchRemoved;
    },
    missingBranchName() {
      return this.sourceBranchRemoved ? 'source' : 'target';
    },
    missingBranchNameMessage() {
      return sprintf(
        s__('mrWidget| Please restore it or use a different %{missingBranchName} branch'),
        {
          missingBranchName: this.missingBranchName,
        },
      );
    },
    message() {
      return sprintf(
        s__(
          'mrWidget|If the %{missingBranchName} branch exists in your local repository, you can merge this merge request manually using the command line',
        ),
        {
          missingBranchName: this.missingBranchName,
        },
      );
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />

    <div class="media-body space-children">
      <span class="bold js-branch-text">
        <span class="capitalize" data-testid="missingBranchName"> {{ missingBranchName }} </span>
        {{ s__('mrWidget|branch does not exist.') }} {{ missingBranchNameMessage }}
        <gl-icon v-gl-tooltip :title="message" :aria-label="message" name="question-o" />
      </span>
    </div>
  </div>
</template>
