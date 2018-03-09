<script>
import timeagoMixin from '../../vue_shared/mixins/timeago';
import tooltip from '../../vue_shared/directives/tooltip';
import { visitUrl } from '../../lib/utils/url_utility';
import createFlash from '../../flash';
import MemoryUsage from './memory_usage.vue';
import StatusIcon from './mr_widget_status_icon.vue';
import MRWidgetService from '../services/mr_widget_service';

export default {
  name: 'Deployment',
  mixins: [
    timeagoMixin,
  ],
  props: {
    deployment: {
      type: Object,
      required: true,
    },
  },
  components: {
    MemoryUsage,
    StatusIcon,
  },
  computed: {
    deployTimeago() {
      return this.timeFormated(this.deployment.deployed_at);
    },
    hasExternalUrls() {
      return this.deployment.external_url && this.deployment.external_url_formatted;
    },
    hasDeploymentTime() {
      return this.deployment.deployed_at && this.deployment.deployed_at_formatted;
    },
    hasDeploymentMeta() {
      return this.deployment.url && this.deployment.name;
    },
  },
  methods: {
    stopEnvironment(deployment) {
      const msg = 'Are you sure you want to stop this environment?';
      const isConfirmed = confirm(msg); // eslint-disable-line

      if (isConfirmed) {
        MRWidgetService.stopEnvironment(deployment.stop_url)
          .then(res => res.data)
          .then((data) => {
            if (data.redirect_url) {
              visitUrl(data.redirect_url);
            }
          })
          .catch(() => createFlash('Something went wrong while stopping this environment. Please try again.'));
      }
    },
  },
};
</script>

<template>
  <div class="mr-widget-heading deploy-heading">
    <div class="ci-widget media">
      <div class="ci-status-icon ci-status-icon-success">
        <span class="js-icon-link icon-link">
          <status-icon status="success" />
        </span>
      </div>
      <div class="media-body">
        <div class="deploy-body">
          <span
            v-if="hasDeploymentMeta">
            Deployed to
          </span>
          <span class="deploy-link">
            <a
              v-if="hasDeploymentMeta"
              :href="deployment.url"
              target="_blank"
              rel="noopener noreferrer nofollow"
              class="js-deploy-meta">
              {{deployment.name}}
            </a>
          </span>
          <span
            v-if="hasExternalUrls">
            on
          </span>
          <span class="deploy-link">
            <a
              v-if="hasExternalUrls"
              :href="deployment.external_url"
              target="_blank"
              rel="noopener noreferrer nofollow"
              class="js-deploy-url">
              <i
                class="fa fa-external-link"
                aria-hidden="true" />
              {{deployment.external_url_formatted}}
            </a>
          </span>
          <span
            v-if="hasDeploymentTime"
            :data-title="deployment.deployed_at_formatted"
            class="js-deploy-time"
            data-toggle="tooltip"
            data-placement="top">
            {{deployTimeago}}
          </span>
          <button
            type="button"
            v-if="deployment.stop_url"
            @click="stopEnvironment(deployment)"
            class="btn btn-default btn-xs">
            Stop environment
          </button>
        </div>
        <memory-usage
          v-if="deployment.metrics_url"
          :metrics-url="deployment.metrics_url"
          :metrics-monitoring-url="deployment.metrics_monitoring_url"
        />
      </div>
    </div>
  </div>
</template>
