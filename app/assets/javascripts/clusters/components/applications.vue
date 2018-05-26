<script>
import _ from 'underscore';
import { s__, sprintf } from '../../locale';
import applicationRow from './application_row.vue';
import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
import { APPLICATION_INSTALLED, INGRESS } from '../constants';

export default {
  components: {
    applicationRow,
    clipboardButton,
  },
  props: {
    applications: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    ingressHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    ingressDnsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    managePrometheusPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    generalApplicationDescription() {
      return sprintf(
        _.escape(
          s__(
            `ClusterIntegration|Install applications on your Kubernetes cluster.
            Read more about %{helpLink}`,
          ),
        ),
        {
          helpLink: `<a href="${this.helpPath}">
              ${_.escape(s__('ClusterIntegration|installing applications'))}
            </a>`,
        },
        false,
      );
    },
    ingressId() {
      return INGRESS;
    },
    ingressInstalled() {
      return this.applications.ingress.status === APPLICATION_INSTALLED;
    },
    ingressExternalIp() {
      return this.applications.ingress.externalIp;
    },
    ingressDescription() {
      const extraCostParagraph = sprintf(
        _.escape(
          s__(
            `ClusterIntegration|%{boldNotice} This will add some extra resources
            like a load balancer, which may incur additional costs depending on
            the hosting provider your Kubernetes cluster is installed on. If you are using
            Google Kubernetes Engine, you can %{pricingLink}.`,
          ),
        ),
        {
          boldNotice: `<strong>${_.escape(s__('ClusterIntegration|Note:'))}</strong>`,
          pricingLink: `<a href="https://cloud.google.com/compute/pricing#lb" target="_blank" rel="noopener noreferrer">
              ${_.escape(s__('ClusterIntegration|check the pricing here'))}</a>`,
        },
        false,
      );

      const externalIpParagraph = sprintf(
        _.escape(
          s__(
            `ClusterIntegration|After installing Ingress, you will need to point your wildcard DNS
            at the generated external IP address in order to view your app after it is deployed. %{ingressHelpLink}`,
          ),
        ),
        {
          ingressHelpLink: `<a href="${this.ingressHelpPath}">
              ${_.escape(s__('ClusterIntegration|More information'))}
            </a>`,
        },
        false,
      );

      return `
          <p>
            ${extraCostParagraph}
          </p>
          <p class="settings-message append-bottom-0">
            ${externalIpParagraph}
          </p>
        `;
    },
    prometheusDescription() {
      return sprintf(
        _.escape(
          s__(
            `ClusterIntegration|Prometheus is an open-source monitoring system
            with %{gitlabIntegrationLink} to monitor deployed applications.`,
          ),
        ),
        {
          gitlabIntegrationLink: `<a href="https://docs.gitlab.com/ce/user/project/integrations/prometheus.html"
              target="_blank" rel="noopener noreferrer">
              ${_.escape(s__('ClusterIntegration|GitLab Integration'))}</a>`,
        },
        false,
      );
    },
  },
};
</script>

<template>
  <section
    id="cluster-applications"
    class="settings no-animate expanded"
  >
    <div class="settings-header">
      <h4>
        {{ s__('ClusterIntegration|Applications') }}
      </h4>
      <p
        class="append-bottom-0"
        v-html="generalApplicationDescription"
      >
      </p>
    </div>

    <div class="settings-content">
      <div class="append-bottom-20">
        <application-row
          id="helm"
          :title="applications.helm.title"
          title-link="https://docs.helm.sh/"
          :status="applications.helm.status"
          :status-reason="applications.helm.statusReason"
          :request-status="applications.helm.requestStatus"
          :request-reason="applications.helm.requestReason"
        >
          <div slot="description">
            {{ s__(`ClusterIntegration|Helm streamlines installing
              and managing Kubernetes applications.
              Tiller runs inside of your Kubernetes Cluster,
              and manages releases of your charts.`) }}
          </div>
        </application-row>
        <application-row
          :id="ingressId"
          :title="applications.ingress.title"
          title-link="https://kubernetes.io/docs/concepts/services-networking/ingress/"
          :status="applications.ingress.status"
          :status-reason="applications.ingress.statusReason"
          :request-status="applications.ingress.requestStatus"
          :request-reason="applications.ingress.requestReason"
        >
          <div slot="description">
            <p>
              {{ s__(`ClusterIntegration|Ingress gives you a way to route
                requests to services based on the request host or path,
                centralizing a number of services into a single entrypoint.`) }}
            </p>

            <template v-if="ingressInstalled">
              <div class="form-group">
                <label for="ingress-ip-address">
                  {{ s__('ClusterIntegration|Ingress IP Address') }}
                </label>
                <div
                  v-if="ingressExternalIp"
                  class="input-group"
                >
                  <input
                    type="text"
                    id="ingress-ip-address"
                    class="form-control js-ip-address"
                    :value="ingressExternalIp"
                    readonly
                  />
                  <span class="input-group-append">
                    <clipboard-button
                      :text="ingressExternalIp"
                      :title="s__('ClusterIntegration|Copy Ingress IP Address to clipboard')"
                      class="input-group-text js-clipboard-btn"
                    />
                  </span>
                </div>
                <input
                  v-else
                  type="text"
                  class="form-control js-ip-address"
                  readonly
                  value="?"
                />
              </div>

              <p
                v-if="!ingressExternalIp"
                class="settings-message js-no-ip-message"
              >
                {{ s__(`ClusterIntegration|The IP address is in
                the process of being assigned. Please check your Kubernetes
                cluster or Quotas on Google Kubernetes Engine if it takes a long time.`) }}

                <a
                  :href="ingressHelpPath"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ __('More information') }}
                </a>
              </p>

              <p>
                {{ s__(`ClusterIntegration|Point a wildcard DNS to this
                generated IP address in order to access
                your application after it has been deployed.`) }}
                <a
                  :href="ingressDnsHelpPath"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ __('More information') }}
                </a>
              </p>

            </template>
            <div
              v-else
              v-html="ingressDescription"
            >
            </div>
          </div>
        </application-row>
        <application-row
          id="prometheus"
          :title="applications.prometheus.title"
          title-link="https://prometheus.io/docs/introduction/overview/"
          :manage-link="managePrometheusPath"
          :status="applications.prometheus.status"
          :status-reason="applications.prometheus.statusReason"
          :request-status="applications.prometheus.requestStatus"
          :request-reason="applications.prometheus.requestReason"
        >
          <div
            slot="description"
            v-html="prometheusDescription"
          >
          </div>
        </application-row>
        <application-row
          id="runner"
          :title="applications.runner.title"
          title-link="https://docs.gitlab.com/runner/"
          :status="applications.runner.status"
          :status-reason="applications.runner.statusReason"
          :request-status="applications.runner.requestStatus"
          :request-reason="applications.runner.requestReason"
        >
          <div slot="description">
            {{ s__(`ClusterIntegration|GitLab Runner connects to this
              project's repository and executes CI/CD jobs,
              pushing results back and deploying,
              applications to production.`) }}
          </div>
        </application-row>
        <!--
          NOTE: Don't forget to update `clusters.scss`
          min-height for this block and uncomment `application_spec` tests
        -->
        <!-- Add GitLab Runner row, all other plumbing is complete -->
      </div>
    </div>
  </section>
</template>
