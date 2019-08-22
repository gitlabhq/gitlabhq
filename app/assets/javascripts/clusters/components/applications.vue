<script>
import _ from 'underscore';
import helmInstallIllustration from '@gitlab/svgs/dist/illustrations/kubernetes-installation.svg';
import { GlLoadingIcon } from '@gitlab/ui';
import elasticsearchLogo from 'images/cluster_app_logos/elasticsearch.png';
import gitlabLogo from 'images/cluster_app_logos/gitlab.png';
import helmLogo from 'images/cluster_app_logos/helm.png';
import jeagerLogo from 'images/cluster_app_logos/jeager.png';
import jupyterhubLogo from 'images/cluster_app_logos/jupyterhub.png';
import kubernetesLogo from 'images/cluster_app_logos/kubernetes.png';
import certManagerLogo from 'images/cluster_app_logos/cert_manager.png';
import knativeLogo from 'images/cluster_app_logos/knative.png';
import meltanoLogo from 'images/cluster_app_logos/meltano.png';
import prometheusLogo from 'images/cluster_app_logos/prometheus.png';
import { s__, sprintf } from '../../locale';
import applicationRow from './application_row.vue';
import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
import KnativeDomainEditor from './knative_domain_editor.vue';
import { CLUSTER_TYPE, APPLICATION_STATUS, INGRESS } from '../constants';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import eventHub from '~/clusters/event_hub';

export default {
  components: {
    applicationRow,
    clipboardButton,
    LoadingButton,
    GlLoadingIcon,
    KnativeDomainEditor,
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
    rbac: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data: () => ({
    elasticsearchLogo,
    gitlabLogo,
    helmLogo,
    jeagerLogo,
    jupyterhubLogo,
    kubernetesLogo,
    certManagerLogo,
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
    ingressExternalEndpoint() {
      return this.applications.ingress.externalIp || this.applications.ingress.externalHostname;
    },
    certManagerInstalled() {
      return this.applications.cert_manager.status === APPLICATION_STATUS.INSTALLED;
    },
    ingressDescription() {
      return sprintf(
        _.escape(
          s__(
            `ClusterIntegration|Installing Ingress may incur additional costs. Learn more about %{pricingLink}.`,
          ),
        ),
        {
          pricingLink: `<strong><a href="https://cloud.google.com/compute/pricing#lb"
              target="_blank" rel="noopener noreferrer">
              ${_.escape(s__('ClusterIntegration|pricing'))}</a></strong>`,
        },
        false,
      );
    },
    certManagerDescription() {
      return sprintf(
        _.escape(
          s__(
            `ClusterIntegration|Cert-Manager is a native Kubernetes certificate management controller that helps with issuing certificates.
            Installing Cert-Manager on your cluster will issue a certificate by %{letsEncrypt} and ensure that certificates
            are valid and up-to-date.`,
          ),
        ),
        {
          letsEncrypt: `<a href="https://letsencrypt.org/"
              target="_blank" rel="noopener noreferrer">
              ${_.escape(s__("ClusterIntegration|Let's Encrypt"))}</a>`,
        },
        false,
      );
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
    knative() {
      return this.applications.knative;
    },
  },
  created() {
    this.helmInstallIllustration = helmInstallIllustration;
  },
  methods: {
    saveKnativeDomain(hostname) {
      eventHub.$emit('saveKnativeDomain', {
        id: 'knative',
        params: { hostname },
      });
    },
    setKnativeHostname(hostname) {
      eventHub.$emit('setKnativeHostname', {
        id: 'knative',
        hostname,
      });
    },
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
      <a :href="helpPath">{{ __('More information') }}</a>
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
        :installed="applications.helm.installed"
        :install-failed="applications.helm.installFailed"
        :uninstallable="applications.helm.uninstallable"
        :uninstall-successful="applications.helm.uninstallSuccessful"
        :uninstall-failed="applications.helm.uninstallFailed"
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
        :installed="applications.ingress.installed"
        :install-failed="applications.ingress.installFailed"
        :uninstallable="applications.ingress.uninstallable"
        :uninstall-successful="applications.ingress.uninstallSuccessful"
        :uninstall-failed="applications.ingress.uninstallFailed"
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
              <label for="ingress-endpoint">{{ s__('ClusterIntegration|Ingress Endpoint') }}</label>
              <div v-if="ingressExternalEndpoint" class="input-group">
                <input
                  id="ingress-endpoint"
                  :value="ingressExternalEndpoint"
                  type="text"
                  class="form-control js-endpoint"
                  readonly
                />
                <span class="input-group-append">
                  <clipboard-button
                    :text="ingressExternalEndpoint"
                    :title="s__('ClusterIntegration|Copy Ingress Endpoint to clipboard')"
                    class="input-group-text js-clipboard-btn"
                  />
                </span>
              </div>
              <div v-else class="input-group">
                <input type="text" class="form-control js-endpoint" readonly />
                <gl-loading-icon
                  class="position-absolute align-self-center ml-2 js-ingress-ip-loading-icon"
                />
              </div>
              <p class="form-text text-muted">
                {{
                  s__(`ClusterIntegration|Point a wildcard DNS to this
                generated endpoint in order to access
                your application after it has been deployed.`)
                }}
                <a :href="ingressDnsHelpPath" target="_blank" rel="noopener noreferrer">
                  {{ __('More information') }}
                </a>
              </p>
            </div>

            <p v-if="!ingressExternalEndpoint" class="settings-message js-no-endpoint-message">
              {{
                s__(`ClusterIntegration|The endpoint is in
              the process of being assigned. Please check your Kubernetes
              cluster or Quotas on Google Kubernetes Engine if it takes a long time.`)
              }}
              <a :href="ingressDnsHelpPath" target="_blank" rel="noopener noreferrer">
                {{ __('More information') }}
              </a>
            </p>
          </template>
          <template v-if="!ingressInstalled">
            <div class="bs-callout bs-callout-info" v-html="ingressDescription"></div>
          </template>
        </div>
      </application-row>
      <application-row
        id="cert_manager"
        :logo-url="certManagerLogo"
        :title="applications.cert_manager.title"
        :status="applications.cert_manager.status"
        :status-reason="applications.cert_manager.statusReason"
        :request-status="applications.cert_manager.requestStatus"
        :request-reason="applications.cert_manager.requestReason"
        :installed="applications.cert_manager.installed"
        :install-failed="applications.cert_manager.installFailed"
        :install-application-request-params="{ email: applications.cert_manager.email }"
        :uninstallable="applications.cert_manager.uninstallable"
        :uninstall-successful="applications.cert_manager.uninstallSuccessful"
        :uninstall-failed="applications.cert_manager.uninstallFailed"
        :disabled="!helmInstalled"
        title-link="https://cert-manager.readthedocs.io/en/latest/#"
      >
        <template>
          <div slot="description">
            <p v-html="certManagerDescription"></p>
            <div class="form-group">
              <label for="cert-manager-issuer-email">
                {{ s__('ClusterIntegration|Issuer Email') }}
              </label>
              <div class="input-group">
                <input
                  v-model="applications.cert_manager.email"
                  :readonly="certManagerInstalled"
                  type="text"
                  class="form-control js-email"
                />
              </div>
              <p class="form-text text-muted">
                {{
                  s__(`ClusterIntegration|Issuers represent a certificate authority.
                You must provide an email address for your Issuer. `)
                }}
                <a
                  href="http://docs.cert-manager.io/en/latest/reference/issuers.html?highlight=email"
                  target="_blank"
                  rel="noopener noreferrer"
                  >{{ __('More information') }}</a
                >
              </p>
            </div>
          </div>
        </template>
      </application-row>
      <application-row
        id="prometheus"
        :logo-url="prometheusLogo"
        :title="applications.prometheus.title"
        :manage-link="managePrometheusPath"
        :status="applications.prometheus.status"
        :status-reason="applications.prometheus.statusReason"
        :request-status="applications.prometheus.requestStatus"
        :request-reason="applications.prometheus.requestReason"
        :installed="applications.prometheus.installed"
        :install-failed="applications.prometheus.installFailed"
        :uninstallable="applications.prometheus.uninstallable"
        :uninstall-successful="applications.prometheus.uninstallSuccessful"
        :uninstall-failed="applications.prometheus.uninstallFailed"
        :disabled="!helmInstalled"
        title-link="https://prometheus.io/docs/introduction/overview/"
      >
        <div slot="description" v-html="prometheusDescription"></div>
      </application-row>
      <application-row
        id="runner"
        :logo-url="gitlabLogo"
        :title="applications.runner.title"
        :status="applications.runner.status"
        :status-reason="applications.runner.statusReason"
        :request-status="applications.runner.requestStatus"
        :request-reason="applications.runner.requestReason"
        :version="applications.runner.version"
        :chart-repo="applications.runner.chartRepo"
        :update-available="applications.runner.updateAvailable"
        :installed="applications.runner.installed"
        :install-failed="applications.runner.installFailed"
        :update-successful="applications.runner.updateSuccessful"
        :update-failed="applications.runner.updateFailed"
        :uninstallable="applications.runner.uninstallable"
        :uninstall-successful="applications.runner.uninstallSuccessful"
        :uninstall-failed="applications.runner.uninstallFailed"
        :disabled="!helmInstalled"
        title-link="https://docs.gitlab.com/runner/"
      >
        <div slot="description">
          {{
            s__(`ClusterIntegration|GitLab Runner connects to the
          repository and executes CI/CD jobs,
          pushing results back and deploying
          applications to production.`)
          }}
        </div>
      </application-row>
      <application-row
        id="jupyter"
        :logo-url="jupyterhubLogo"
        :title="applications.jupyter.title"
        :status="applications.jupyter.status"
        :status-reason="applications.jupyter.statusReason"
        :request-status="applications.jupyter.requestStatus"
        :request-reason="applications.jupyter.requestReason"
        :installed="applications.jupyter.installed"
        :install-failed="applications.jupyter.installFailed"
        :uninstallable="applications.jupyter.uninstallable"
        :uninstall-successful="applications.jupyter.uninstallSuccessful"
        :uninstall-failed="applications.jupyter.uninstallFailed"
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

          <template v-if="ingressExternalEndpoint">
            <div class="form-group">
              <label for="jupyter-hostname">{{ s__('ClusterIntegration|Jupyter Hostname') }}</label>

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

              <p v-if="ingressInstalled" class="form-text text-muted">
                {{
                  s__(`ClusterIntegration|Replace this with your own hostname if you want.
                If you do so, point hostname to Ingress IP Address from above.`)
                }}
                <a :href="ingressDnsHelpPath" target="_blank" rel="noopener noreferrer">
                  {{ __('More information') }}
                </a>
              </p>
            </div>
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
        :installed="applications.knative.installed"
        :install-failed="applications.knative.installFailed"
        :install-application-request-params="{ hostname: applications.knative.hostname }"
        :uninstallable="applications.knative.uninstallable"
        :uninstall-successful="applications.knative.uninstallSuccessful"
        :uninstall-failed="applications.knative.uninstallFailed"
        :updateable="false"
        :disabled="!helmInstalled"
        v-bind="applications.knative"
        title-link="https://github.com/knative/docs"
      >
        <div slot="description">
          <span v-if="!rbac">
            <p v-if="!rbac" class="rbac-notice bs-callout bs-callout-info append-bottom-0">
              {{
                s__(`ClusterIntegration|You must have an RBAC-enabled cluster
              to install Knative.`)
              }}
              <a :href="helpPath" target="_blank" rel="noopener noreferrer">
                {{ __('More information') }}
              </a>
            </p>
            <br />
          </span>
          <p>
            {{
              s__(`ClusterIntegration|Knative extends Kubernetes to provide
            a set of middleware components that are essential to build modern,
            source-centric, and container-based applications that can run
            anywhere: on premises, in the cloud, or even in a third-party data center.`)
            }}
          </p>

          <knative-domain-editor
            v-if="knative.installed || (helmInstalled && rbac)"
            :knative="knative"
            :ingress-dns-help-path="ingressDnsHelpPath"
            @save="saveKnativeDomain"
            @set="setKnativeHostname"
          />
        </div>
      </application-row>
    </div>
  </section>
</template>
