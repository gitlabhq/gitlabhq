import '~/lib/utils/datetime_utility';
import pipelineStatusIcon from '../../vue_shared/components/pipeline_status_icon';
import { statusClassToSvgMap } from '../../vue_shared/pipeline_svg_icons';

export default {
  name: 'MRWidgetDeployment',
  props: {
    mr: { type: Object, required: true },
  },
  computed: {
    svg() {
      return statusClassToSvgMap.icon_status_success;
    },
  },
  components: {
    'pipeline-status-icon': pipelineStatusIcon,
  },
  methods: {
    formatDate(date) {
      return gl.utils.getTimeago().format(date);
    },
    hasExternalUrls(deployment = {}) {
      return deployment.external_url && deployment.external_url_formatted;
    },
    hasDeploymentTime(deployment = {}) {
      return deployment.deployed_at && deployment.deployed_at_formatted;
    },
    hasDeploymentMeta(deployment = {}) {
      return deployment.url && deployment.name;
    },
    stopEnvironment(deployment) {
      const msg = 'Are you sure you want to stop this environment?';
      const isConfirmed = confirm(msg); // eslint-disable-line

      if (isConfirmed) {
        // TODO: Handle deployment cancel when backend is implemented.
      }
    },
  },
  template: `
    <div class="mr-widget-heading">
      <div class="ci_widget" v-for="deployment in mr.deployments">
        <div class="ci-status-icon ci-status-icon-success">
          <span class="js-icon-link">
            <span v-html="svg" aria-hidden="true"></span>
          </span>
        </div>
        <span>
          <span v-if="hasDeploymentMeta(deployment)">Deployed to</span>
          <a
            v-if="hasDeploymentMeta(deployment)"
            :href="deployment.url"
            target="_blank" rel="noopener noreferrer" class="js-deploy-meta">
            {{deployment.name}}
          </a>
          <span v-if="hasExternalUrls(deployment)">on</span>
          <a
            v-if="hasExternalUrls(deployment)"
            :href="deployment.external_url"
            target="_blank" rel="noopener noreferrer" class="js-deploy-url">
            {{deployment.external_url_formatted}}
          </a>
          <span
            v-if="hasDeploymentTime(deployment)"
            :data-title="deployment.deployed_at_formatted"
            class="js-deploy-time" data-toggle="tooltip" data-placement="top">
            {{formatDate(deployment.deployed_at)}}
          </span>
          <button
            v-if="deployment.stop_url"
            @click="stopEnvironment(deployment)"
            class="btn btn-default btn-xs" type="button">
            Stop environment
          </button>
        </span>
      </div>
    </div>
  `,
};

