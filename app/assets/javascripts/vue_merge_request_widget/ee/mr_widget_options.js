import CEWidgetOptions from '../mr_widget_options';
import WidgetApprovals from './components/approvals/mr_widget_approvals';
import GeoSecondaryNode from './components/states/mr_widget_secondary_geo_node';
import RebaseState from './components/states/mr_widget_rebase';

export default {
  extends: CEWidgetOptions,
  components: {
    'mr-widget-approvals': WidgetApprovals,
    'mr-widget-geo-secondary-node': GeoSecondaryNode,
    'mr-widget-rebase': RebaseState,
  },
  computed: {
    shouldRenderApprovals() {
      return this.mr.approvalsRequired;
    },
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline
        v-if="shouldRenderPipelines"
        :mr="mr" />
      <mr-widget-deployment
        v-if="shouldRenderDeployments"
        :mr="mr"
        :service="service" />
      <mr-widget-approvals
        v-if="mr.approvalsRequired"
        :mr="mr"
        :service="service" />
      <component
        :is="componentName"
        :mr="mr"
        :service="service" />
      <mr-widget-related-links
        v-if="shouldRenderRelatedLinks"
        :related-links="mr.relatedLinks" />
      <mr-widget-merge-help v-if="shouldRenderMergeHelp" />
    </div>
  `,
};
