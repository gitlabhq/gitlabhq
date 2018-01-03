<script>
import _ from 'underscore';
import { s__, sprintf } from '../../locale';
import applicationRow from './application_row.vue';

export default {
  props: {
    applications: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    helpPath: {
      type: String,
      required: false,
    },
  },
  components: {
    applicationRow,
  },
  computed: {
    generalApplicationDescription() {
      return sprintf(
        _.escape(s__('ClusterIntegration|Install applications on your cluster. Read more about %{helpLink}')), {
          helpLink: `<a href="${this.helpPath}">
            ${_.escape(s__('ClusterIntegration|installing applications'))}
          </a>`,
        },
        false,
      );
    },
    helmTillerDescription() {
      return _.escape(s__(
        `ClusterIntegration|Helm streamlines installing and managing Kubernets applications.
        Tiller runs inside of your Kubernetes Cluster, and manages
        releases of your charts.`,
      ));
    },
    ingressDescription() {
      const descriptionParagraph = _.escape(s__(
        `ClusterIntegration|Ingress gives you a way to route requests to services based on the
        request host or path, centralizing a number of services into a single entrypoint.`,
      ));

      const extraCostParagraph = sprintf(
        _.escape(s__('ClusterIntegration|%{boldNotice} This will add some extra resources like a load balancer, which incur additional costs. See %{pricingLink}')), {
          boldNotice: `<strong>${_.escape(s__('ClusterIntegration|Note:'))}</strong>`,
          pricingLink: `<a href="https://cloud.google.com/compute/pricing#lb" target="_blank" rel="noopener noreferrer">
            ${_.escape(s__('ClusterIntegration|GKE pricing'))}
          </a>`,
        },
        false,
      );

      return `
        <p>
          ${descriptionParagraph}
        </p>
        <p class="append-bottom-0">
          ${extraCostParagraph}
        </p>
      `;
    },
    gitlabRunnerDescription() {
      return _.escape(s__(
        `ClusterIntegration|GitLab Runner is the open source project that is used to run your jobs
        and send the results back to GitLab.`,
      ));
    },
    prometheusDescription() {
      return sprintf(
        _.escape(s__('ClusterIntegration|Prometheus is an open-source monitoring system with %{gitlabIntegrationLink} to monitor deployed applications.')), {
          gitlabIntegrationLink: `<a href="https://docs.gitlab.com/ce/user/project/integrations/prometheus.html", target="_blank" rel="noopener noreferrer">
            ${_.escape(s__('ClusterIntegration|Gitlab Integration'))}
          </a>`,
        },
        false,
      );
    },
  },
};
</script>

<template>
  <section class="settings no-animate expanded">
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
          :description="helmTillerDescription"
          :status="applications.helm.status"
          :status-reason="applications.helm.statusReason"
          :request-status="applications.helm.requestStatus"
          :request-reason="applications.helm.requestReason"
        />
        <application-row
         id="ingress"
         :title="applications.ingress.title"
         title-link="https://kubernetes.io/docs/concepts/services-networking/ingress/"
         :description="ingressDescription"
         :status="applications.ingress.status"
         :status-reason="applications.ingress.statusReason"
         :request-status="applications.ingress.requestStatus"
         :request-reason="applications.ingress.requestReason"
       />
       <application-row
         id="prometheus"
         :title="applications.prometheus.title"
         title-link="https://prometheus.io/docs/introduction/overview/"
         :description="prometheusDescription"
         :status="applications.prometheus.status"
         :status-reason="applications.prometheus.statusReason"
         :request-status="applications.prometheus.requestStatus"
         :request-reason="applications.prometheus.requestReason"
       />
        <!-- NOTE: Don't forget to update `clusters.scss` min-height for this block and uncomment `application_spec` tests -->
        <!-- Add GitLab Runner row, all other plumbing is complete -->
      </div>
    </div>
  </section>
</template>
