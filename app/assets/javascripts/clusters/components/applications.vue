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
import crossplaneLogo from 'images/cluster_app_logos/crossplane.png';
import knativeLogo from 'images/cluster_app_logos/knative.png';
import meltanoLogo from 'images/cluster_app_logos/meltano.png';
import prometheusLogo from 'images/cluster_app_logos/prometheus.png';
import elasticStackLogo from 'images/cluster_app_logos/elastic_stack.png';
import { s__, sprintf } from '../../locale';
import applicationRow from './application_row.vue';
import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
import KnativeDomainEditor from './knative_domain_editor.vue';
import { CLUSTER_TYPE, PROVIDER_TYPE, APPLICATION_STATUS, INGRESS } from '../constants';
import eventHub from '~/clusters/event_hub';
import CrossplaneProviderStack from './crossplane_provider_stack.vue';

export default {
  components: {
    applicationRow,
    clipboardButton,
    GlLoadingIcon,
    KnativeDomainEditor,
    CrossplaneProviderStack,
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
    ingressModSecurityHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    cloudRunHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    managePrometheusPath: {
      type: String,
      required: false,
      default: '',
    },
    providerType: {
      type: String,
      required: false,
      default: '',
    },
    preInstalledKnative: {
      type: Boolean,
      required: false,
      default: false,
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
    crossplaneLogo,
    knativeLogo,
    meltanoLogo,
    prometheusLogo,
    elasticStackLogo,
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
    ingressEnableModsecurity() {
      return this.applications.ingress.modsecurity_enabled;
    },
    ingressExternalEndpoint() {
      return this.applications.ingress.externalIp || this.applications.ingress.externalHostname;
    },
    certManagerInstalled() {
      return this.applications.cert_manager.status === APPLICATION_STATUS.INSTALLED;
    },
    crossplaneInstalled() {
      return this.applications.crossplane.status === APPLICATION_STATUS.INSTALLED;
    },
    enableClusterApplicationElasticStack() {
      return gon.features && gon.features.enableClusterApplicationElasticStack;
    },
    ingressModSecurityDescription() {
      const escapedUrl = _.escape(this.ingressModSecurityHelpPath);

      return sprintf(
        s__('ClusterIntegration|Learn more about %{startLink}ModSecurity%{endLink}'),
        {
          startLink: `<a href="${escapedUrl}" target="_blank" rel="noopener noreferrer">`,
          endLink: '</a>',
        },
        false,
      );
    },
    ingressDescription() {
      return sprintf(
        _.escape(
          s__(
            `ClusterIntegration|Installing Ingress may incur additional costs. Learn more about %{pricingLink}.`,
          ),
        ),
        {
          pricingLink: `<a href="https://cloud.google.com/compute/pricing#lb"
              target="_blank" rel="noopener noreferrer">
              ${_.escape(s__('ClusterIntegration|pricing'))}</a>`,
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
    crossplaneDescription() {
      return sprintf(
        _.escape(
          s__(
            `ClusterIntegration|Crossplane enables declarative provisioning of managed services from your cloud of choice using %{kubectl} or %{gitlabIntegrationLink}.
Crossplane runs inside your Kubernetes cluster and supports secure connectivity and secrets management between app containers and the cloud services they depend on.`,
          ),
        ),
        {
          gitlabIntegrationLink: `<a href="https://docs.gitlab.com/ee/user/clusters/applications.html#crossplane"
          target="_blank" rel="noopener noreferrer">
          ${_.escape(s__('ClusterIntegration|Gitlab Integration'))}</a>`,
          kubectl: `<code>kubectl</code>`,
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
    elasticStackInstalled() {
      return this.applications.elastic_stack.status === APPLICATION_STATUS.INSTALLED;
    },
    knative() {
      return this.applications.knative;
    },
    crossplane() {
      return this.applications.crossplane;
    },
    cloudRun() {
      return this.providerType === PROVIDER_TYPE.GCP && this.preInstalledKnative;
    },
    installedVia() {
      if (this.cloudRun) {
        return sprintf(
          _.escape(s__(`ClusterIntegration|installed via %{installed_via}`)),
          {
            installed_via: `<a href="${
              this.cloudRunHelpPath
            }" target="_blank" rel="noopener noreferrer">${_.escape(
              s__('ClusterIntegration|Cloud Run'),
            )}</a>`,
          },
          false,
        );
      }
      return null;
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
    setCrossplaneProviderStack(stack) {
      eventHub.$emit('setCrossplaneProviderStack', {
        id: 'crossplane',
        stack,
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
        :install-application-request-params="{
          modsecurity_enabled: applications.ingress.modsecurity_enabled,
        }"
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

          <template>
            <div class="form-group">
              <div class="form-check form-check-inline">
                <input
                  v-model="applications.ingress.modsecurity_enabled"
                  :disabled="ingressInstalled"
                  type="checkbox"
                  autocomplete="off"
                  class="form-check-input"
                />
                <label class="form-check-label label-bold" for="ingress-enable-modsecurity">
                  {{ s__('ClusterIntegration|Enable Web Application Firewall') }}
                </label>
              </div>
              <p class="form-text text-muted">
                <strong v-html="ingressModSecurityDescription"></strong>
              </p>
            </div>
          </template>

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
                    :title="s__('ClusterIntegration|Copy Ingress Endpoint')"
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
            <div class="bs-callout bs-callout-info">
              <strong v-html="ingressDescription"></strong>
            </div>
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
        id="crossplane"
        :logo-url="crossplaneLogo"
        :title="applications.crossplane.title"
        :status="applications.crossplane.status"
        :status-reason="applications.crossplane.statusReason"
        :request-status="applications.crossplane.requestStatus"
        :request-reason="applications.crossplane.requestReason"
        :installed="applications.crossplane.installed"
        :install-failed="applications.crossplane.installFailed"
        :uninstallable="applications.crossplane.uninstallable"
        :uninstall-successful="applications.crossplane.uninstallSuccessful"
        :uninstall-failed="applications.crossplane.uninstallFailed"
        :install-application-request-params="{ stack: applications.crossplane.stack }"
        :disabled="!helmInstalled"
        title-link="https://crossplane.io"
      >
        <template>
          <div slot="description">
            <p v-html="crossplaneDescription"></p>
            <div class="form-group">
              <CrossplaneProviderStack :crossplane="crossplane" @set="setCrossplaneProviderStack" />
            </div>
          </div>
        </template>
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
                    :title="s__('ClusterIntegration|Copy Jupyter Hostname')"
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
        :installed-via="installedVia"
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
            v-if="(knative.installed || (helmInstalled && rbac)) && !preInstalledKnative"
            :knative="knative"
            :ingress-dns-help-path="ingressDnsHelpPath"
            @save="saveKnativeDomain"
            @set="setKnativeHostname"
          />
        </div>
      </application-row>
      <application-row
        v-if="enableClusterApplicationElasticStack"
        id="elastic_stack"
        :logo-url="elasticStackLogo"
        :title="applications.elastic_stack.title"
        :status="applications.elastic_stack.status"
        :status-reason="applications.elastic_stack.statusReason"
        :request-status="applications.elastic_stack.requestStatus"
        :request-reason="applications.elastic_stack.requestReason"
        :version="applications.elastic_stack.version"
        :chart-repo="applications.elastic_stack.chartRepo"
        :update-available="applications.elastic_stack.updateAvailable"
        :installed="applications.elastic_stack.installed"
        :install-failed="applications.elastic_stack.installFailed"
        :update-successful="applications.elastic_stack.updateSuccessful"
        :update-failed="applications.elastic_stack.updateFailed"
        :uninstallable="applications.elastic_stack.uninstallable"
        :uninstall-successful="applications.elastic_stack.uninstallSuccessful"
        :uninstall-failed="applications.elastic_stack.uninstallFailed"
        :disabled="!helmInstalled"
        title-link="https://github.com/helm/charts/tree/master/stable/elastic-stack"
      >
        <div slot="description">
          <p>
            {{
              s__(
                `ClusterIntegration|The elastic stack collects logs from all pods in your cluster`,
              )
            }}
          </p>
        </div>
      </application-row>
    </div>
  </section>
</template>
