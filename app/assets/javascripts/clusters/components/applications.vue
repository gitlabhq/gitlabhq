<script>
import _ from 'underscore';
import helmInstallIllustration from '@gitlab/svgs/dist/illustrations/kubernetes-installation.svg';
import elasticsearchLogo from 'images/cluster_app_logos/elasticsearch.png';
import gitlabLogo from 'images/cluster_app_logos/gitlab.png';
import helmLogo from 'images/cluster_app_logos/helm.png';
import jeagerLogo from 'images/cluster_app_logos/jeager.png';
import jupyterhubLogo from 'images/cluster_app_logos/jupyterhub.png';
import kubernetesLogo from 'images/cluster_app_logos/kubernetes.png';
import knativeLogo from 'images/cluster_app_logos/knative.png';
import meltanoLogo from 'images/cluster_app_logos/meltano.png';
import prometheusLogo from 'images/cluster_app_logos/prometheus.png';
import { s__, sprintf } from '../../locale';
import applicationRow from './application_row.vue';
import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
import { CLUSTER_TYPE, APPLICATION_STATUS, INGRESS } from '../constants';

export default {
  components: {
    applicationRow,
    clipboardButton,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: CLUSTER_TYPE.PROJECT,
    },
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
  data: () => ({
    elasticsearchLogo,
    gitlabLogo,
    helmLogo,
    jeagerLogo,
    jupyterhubLogo,
    kubernetesLogo,
    knativeLogo,
    meltanoLogo,
    prometheusLogo,
  }),
  computed: {
    isProjectCluster() {
      return this.type === CLUSTER_TYPE.PROJECT;
    },
    helmInstalled() {
      return (
        this.applications.helm.status === APPLICATION_STATUS.INSTALLED ||
        this.applications.helm.status === APPLICATION_STATUS.UPDATED
      );
    },
    ingressId() {
      return INGRESS;
    },
    ingressInstalled() {
      return this.applications.ingress.status === APPLICATION_STATUS.INSTALLED;
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
    jupyterInstalled() {
      return this.applications.jupyter.status === APPLICATION_STATUS.INSTALLED;
    },
    jupyterHostname() {
      return this.applications.jupyter.hostname;
    },
    knativeInstalled() {
      return this.applications.knative.status === APPLICATION_STATUS.INSTALLED;
    },
  },
  created() {
    this.helmInstallIllustration = helmInstallIllustration;
  },
};
</script>

<template>
  <section id="cluster-applications">
    <h4>{{ s__('ClusterIntegration|Applications') }}</h4>
    <p class="append-bottom-0">
      {{
        s__(`ClusterIntegration|Choose which applications to install on your Kubernetes cluster.
        Helm Tiller is required to install any of the following applications.`)
      }}
      <a :href="helpPath"> {{ __('More information') }} </a>
    </p>

    <div class="cluster-application-list prepend-top-10">
      <application-row
        id="helm"
        :logo-url="helmLogo"
        :title="applications.helm.title"
        :status="applications.helm.status"
        :status-reason="applications.helm.statusReason"
        :request-status="applications.helm.requestStatus"
        :request-reason="applications.helm.requestReason"
        class="rounded-top"
        title-link="https://docs.helm.sh/"
      >
        <div slot="description">
          {{
            s__(`ClusterIntegration|Helm streamlines installing
            and managing Kubernetes applications.
            Tiller runs inside of your Kubernetes Cluster,
            and manages releases of your charts.`)
          }}
        </div>
      </application-row>
      <div v-show="!helmInstalled" class="cluster-application-warning">
        <div class="svg-container" v-html="helmInstallIllustration"></div>
        {{
          s__(`ClusterIntegration|You must first install Helm Tiller before
          installing the applications below`)
        }}
      </div>
      <application-row
        :id="ingressId"
        :logo-url="kubernetesLogo"
        :title="applications.ingress.title"
        :status="applications.ingress.status"
        :status-reason="applications.ingress.statusReason"
        :request-status="applications.ingress.requestStatus"
        :request-reason="applications.ingress.requestReason"
        :disabled="!helmInstalled"
        title-link="https://kubernetes.io/docs/concepts/services-networking/ingress/"
      >
        <div slot="description">
          <p>
            {{
              s__(`ClusterIntegration|Ingress gives you a way to route
              requests to services based on the request host or path,
              centralizing a number of services into a single entrypoint.`)
            }}
          </p>

          <template v-if="ingressInstalled">
            <div class="form-group">
              <label for="ingress-ip-address">
                {{ s__('ClusterIntegration|Ingress IP Address') }}
              </label>
              <div v-if="ingressExternalIp" class="input-group">
                <input
                  id="ingress-ip-address"
                  :value="ingressExternalIp"
                  type="text"
                  class="form-control js-ip-address"
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
              <input v-else type="text" class="form-control js-ip-address" readonly value="?" />
            </div>

            <p v-if="!ingressExternalIp" class="settings-message js-no-ip-message">
              {{
                s__(`ClusterIntegration|The IP address is in
              the process of being assigned. Please check your Kubernetes
              cluster or Quotas on Google Kubernetes Engine if it takes a long time.`)
              }}

              <a :href="ingressHelpPath" target="_blank" rel="noopener noreferrer">
                {{ __('More information') }}
              </a>
            </p>

            <p>
              {{
                s__(`ClusterIntegration|Point a wildcard DNS to this
              generated IP address in order to access
              your application after it has been deployed.`)
              }}
              <a :href="ingressDnsHelpPath" target="_blank" rel="noopener noreferrer">
                {{ __('More information') }}
              </a>
            </p>
          </template>
          <div v-html="ingressDescription"></div>
        </div>
      </application-row>
      <application-row
        v-if="isProjectCluster"
        id="prometheus"
        :logo-url="prometheusLogo"
        :title="applications.prometheus.title"
        :manage-link="managePrometheusPath"
        :status="applications.prometheus.status"
        :status-reason="applications.prometheus.statusReason"
        :request-status="applications.prometheus.requestStatus"
        :request-reason="applications.prometheus.requestReason"
        :disabled="!helmInstalled"
        title-link="https://prometheus.io/docs/introduction/overview/"
      >
        <div slot="description" v-html="prometheusDescription"></div>
      </application-row>
      <application-row
        v-if="isProjectCluster"
        id="runner"
        :logo-url="gitlabLogo"
        :title="applications.runner.title"
        :status="applications.runner.status"
        :status-reason="applications.runner.statusReason"
        :request-status="applications.runner.requestStatus"
        :request-reason="applications.runner.requestReason"
        :disabled="!helmInstalled"
        title-link="https://docs.gitlab.com/runner/"
      >
        <div slot="description">
          {{
            s__(`ClusterIntegration|GitLab Runner connects to this
            project's repository and executes CI/CD jobs,
            pushing results back and deploying,
            applications to production.`)
          }}
        </div>
      </application-row>
      <application-row
        v-if="isProjectCluster"
        id="jupyter"
        :logo-url="jupyterhubLogo"
        :title="applications.jupyter.title"
        :status="applications.jupyter.status"
        :status-reason="applications.jupyter.statusReason"
        :request-status="applications.jupyter.requestStatus"
        :request-reason="applications.jupyter.requestReason"
        :install-application-request-params="{ hostname: applications.jupyter.hostname }"
        :disabled="!helmInstalled"
        title-link="https://jupyterhub.readthedocs.io/en/stable/"
      >
        <div slot="description">
          <p>
            {{
              s__(`ClusterIntegration|JupyterHub, a multi-user Hub, spawns,
              manages, and proxies multiple instances of the single-user
              Jupyter notebook server. JupyterHub can be used to serve
              notebooks to a class of students, a corporate data science group,
              or a scientific research group.`)
            }}
          </p>

          <template v-if="ingressExternalIp">
            <div class="form-group">
              <label for="jupyter-hostname">
                {{ s__('ClusterIntegration|Jupyter Hostname') }}
              </label>

              <div class="input-group">
                <input
                  v-model="applications.jupyter.hostname"
                  :readonly="jupyterInstalled"
                  type="text"
                  class="form-control js-hostname"
                />
                <span class="input-group-btn">
                  <clipboard-button
                    :text="jupyterHostname"
                    :title="s__('ClusterIntegration|Copy Jupyter Hostname to clipboard')"
                    class="js-clipboard-btn"
                  />
                </span>
              </div>
            </div>
            <p v-if="ingressInstalled">
              {{
                s__(`ClusterIntegration|Replace this with your own hostname if you want.
              If you do so, point hostname to Ingress IP Address from above.`)
              }}
              <a :href="ingressDnsHelpPath" target="_blank" rel="noopener noreferrer">
                {{ __('More information') }}
              </a>
            </p>
          </template>
        </div>
      </application-row>
      <application-row
        id="knative"
        :logo-url="knativeLogo"
        :title="applications.knative.title"
        :status="applications.knative.status"
        :status-reason="applications.knative.statusReason"
        :request-status="applications.knative.requestStatus"
        :request-reason="applications.knative.requestReason"
        :install-application-request-params="{ hostname: applications.knative.hostname }"
        :disabled="!helmInstalled"
        class="hide-bottom-border rounded-bottom"
        title-link="https://github.com/knative/docs"
      >
        <div slot="description">
          <p>
            {{
              s__(`ClusterIntegration|A Knative build extends Kubernetes
              and utilizes existing Kubernetes primitives to provide you with
              the ability to run on-cluster container builds from source.
              For example, you can write a build that uses Kubernetes-native
              resources to obtain your source code from a repository,
              build it into container a image, and then run that image.`)
            }}
          </p>

          <template v-if="knativeInstalled">
            <div class="form-group">
              <label for="knative-domainname">
                {{ s__('ClusterIntegration|Knative Domain Name:') }}
              </label>
              <input
                id="knative-domainname"
                v-model="applications.knative.hostname"
                type="text"
                class="form-control js-domainname"
                readonly
              />
            </div>
          </template>
          <template v-else>
            <div class="form-group">
              <label for="knative-domainname">
                {{ s__('ClusterIntegration|Knative Domain Name:') }}
              </label>
              <input
                id="knative-domainname"
                v-model="applications.knative.hostname"
                type="text"
                class="form-control js-domainname"
              />
            </div>
          </template>
        </div>
      </application-row>
    </div>
  </section>
</template>
