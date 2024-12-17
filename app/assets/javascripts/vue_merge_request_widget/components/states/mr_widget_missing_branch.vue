<script>
import { GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { sprintf } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import missingBranchQuery from '../../queries/states/missing_branch.query.graphql';
import {
  MR_WIDGET_MISSING_BRANCH_WHICH,
  MR_WIDGET_MISSING_BRANCH_RESTORE,
  MR_WIDGET_MISSING_BRANCH_MANUALCLI,
} from '../../i18n';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetMissingBranch',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlSprintf,
    StatusIcon,
    HelpIcon,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    state: {
      query: missingBranchQuery,
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
    type() {
      return this.mr.sourceBranchRemoved ? 'source' : 'target';
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
    <status-icon :show-disabled-button="true" status="failed" />

    <div class="media-body">
      <span class="js-branch-text" data-testid="widget-content">
        <span class="gl-font-bold">
          <gl-sprintf :message="warning">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </span>
        {{ restore }}
        <help-icon v-gl-tooltip :title="message" :aria-label="message" class="gl-cursor-pointer" />
      </span>
    </div>
  </div>
</template>
