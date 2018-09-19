<script>
import Icon from '~/vue_shared/components/icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import timeagoMixin from '../../vue_shared/mixins/timeago';
import tooltip from '../../vue_shared/directives/tooltip';
import LoadingButton from '../../vue_shared/components/loading_button.vue';
import { visitUrl } from '../../lib/utils/url_utility';
import createFlash from '../../flash';
import MemoryUsage from './memory_usage.vue';
import StatusIcon from './mr_widget_status_icon.vue';
import MRWidgetService from '../services/mr_widget_service';

export default {
  name: 'Deployment',
  components: {
    LoadingButton,
    MemoryUsage,
    StatusIcon,
    Icon,
    TooltipOnTruncate,
  },
  directives: {
    tooltip,
  },
  mixins: [
    timeagoMixin,
  ],
  props: {
    deployment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isStopping: false,
    };
  },
  computed: {
    deployTimeago() {
      return this.timeFormated(this.deployment.deployed_at);
    },
    hasExternalUrls() {
      return !!(this.deployment.external_url && this.deployment.external_url_formatted);
    },
    hasDeploymentTime() {
      return !!(this.deployment.deployed_at && this.deployment.deployed_at_formatted);
    },
    hasDeploymentMeta() {
      return !!(this.deployment.url && this.deployment.name);
    },
    hasMetrics() {
      return !!(this.deployment.metrics_url);
    },
  },
  methods: {
    stopEnvironment() {
      const msg = 'Are you sure you want to stop this environment?';
      const isConfirmed = confirm(msg); // eslint-disable-line

      if (isConfirmed) {
        this.isStopping = true;

        MRWidgetService.stopEnvironment(this.deployment.stop_url)
          .then(res => res.data)
          .then((data) => {
            if (data.redirect_url) {
              visitUrl(data.redirect_url);
            }

            this.isStopping = false;
          })
          .catch(() => {
            createFlash('Something went wrong while stopping this environment. Please try again.');
            this.isStopping = false;
          });
      }
    },
  },
};
</script>

<template>
  <div class="mr-widget-heading deploy-heading append-bottom-default">
    <div class="ci-widget media">
      <div class="media-body">
        <div class="deploy-body">
          <div class="deployment-info">
            <template v-if="hasDeploymentMeta">
              <span>
                Deployed to
              </span>
              <tooltip-on-truncate
                :title="deployment.name"
                truncate-target="child"
                class="deploy-link label-truncate"
              >
                <a
                  :href="deployment.url"
                  target="_blank"
                  rel="noopener noreferrer nofollow"
                  class="js-deploy-meta"
                >
                  {{ deployment.name }}
                </a>
              </tooltip-on-truncate>
            </template>
            <span
              v-tooltip
              v-if="hasDeploymentTime"
              :title="deployment.deployed_at_formatted"
              class="js-deploy-time"
            >
              {{ deployTimeago }}
            </span>
            <memory-usage
              v-if="hasMetrics"
              :metrics-url="deployment.metrics_url"
              :metrics-monitoring-url="deployment.metrics_monitoring_url"
            />
          </div>
          <div>
            <a
              v-if="hasExternalUrls"
              :href="deployment.external_url"
              target="_blank"
              rel="noopener noreferrer nofollow"
              class="deploy-link js-deploy-url btn btn-default btn-sm inline"
            >
              <span>
                View app
                <icon name="external-link" />
              </span>
            </a>
            <loading-button
              v-if="deployment.stop_url"
              :loading="isStopping"
              container-class="btn btn-default btn-sm inline prepend-left-4"
              title="Stop environment"
              @click="stopEnvironment"
            >
              <icon name="stop" />
            </loading-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
