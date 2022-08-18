<script>
import { GlIcon, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import missingBranchQuery from '../../queries/states/missing_branch.query.graphql';
import {
  MR_WIDGET_MISSING_BRANCH_WHICH,
  MR_WIDGET_MISSING_BRANCH_RESTORE,
  MR_WIDGET_MISSING_BRANCH_MANUALCLI,
} from '../../i18n';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetMissingBranch',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlSprintf,
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
    type() {
      return this.sourceBranchRemoved ? 'source' : 'target';
    },
    name() {
      return this.type === 'source' ? this.mr.sourceBranch : this.mr.targetBranch;
    },
    warning() {
      return sprintf(MR_WIDGET_MISSING_BRANCH_WHICH, { type: this.type, name: this.name });
    },
    restore() {
      return sprintf(MR_WIDGET_MISSING_BRANCH_RESTORE, { type: this.type });
    },
    message() {
      return sprintf(MR_WIDGET_MISSING_BRANCH_MANUALCLI, { type: this.type });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />

    <div class="media-body space-children">
      <span class="gl-ml-0! gl-text-body! bold js-branch-text" data-testid="widget-content">
        <gl-sprintf :message="warning">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
        {{ restore }}
        <gl-icon
          v-gl-tooltip
          :title="message"
          :aria-label="message"
          name="question-o"
          class="gl-text-blue-600 gl-cursor-pointer"
        />
      </span>
    </div>
  </div>
</template>
