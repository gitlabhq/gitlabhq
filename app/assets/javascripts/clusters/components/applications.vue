<script>
import { GlLoadingIcon, GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import certManagerLogo from 'images/cluster_app_logos/cert_manager.png';
import crossplaneLogo from 'images/cluster_app_logos/crossplane.png';
import elasticStackLogo from 'images/cluster_app_logos/elastic_stack.png';
import fluentdLogo from 'images/cluster_app_logos/fluentd.png';
import gitlabLogo from 'images/cluster_app_logos/gitlab.png';
import helmLogo from 'images/cluster_app_logos/helm.png';
import jupyterhubLogo from 'images/cluster_app_logos/jupyterhub.png';
import knativeLogo from 'images/cluster_app_logos/knative.png';
import kubernetesLogo from 'images/cluster_app_logos/kubernetes.png';
import prometheusLogo from 'images/cluster_app_logos/prometheus.png';
import eventHub from '~/clusters/event_hub';
import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
import { CLUSTER_TYPE, PROVIDER_TYPE, APPLICATION_STATUS, INGRESS } from '../constants';
import applicationRow from './application_row.vue';
import CrossplaneProviderStack from './crossplane_provider_stack.vue';
import FluentdOutputSettings from './fluentd_output_settings.vue';
import IngressModsecuritySettings from './ingress_modsecurity_settings.vue';
import KnativeDomainEditor from './knative_domain_editor.vue';

export default {
  components: {
    applicationRow,
    clipboardButton,
    GlLoadingIcon,
    GlSprintf,
    GlLink,
    KnativeDomainEditor,
    CrossplaneProviderStack,
    IngressModsecuritySettings,
    FluentdOutputSettings,
    GlAlert,
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
    helmHelpPath: {
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
    ciliumHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
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
    jupyterInstalled() {
      return this.applications.jupyter.status === APPLICATION_STATUS.INSTALLED;
    },
    jupyterHostname() {
      return this.applications.jupyter.hostname;
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
    ingress() {
      return this.applications.ingress;
    },
  },
  methods: {
    saveKnativeDomain() {
      eventHub.$emit('saveKnativeDomain', {
        id: 'knative',
        params: {
          hostname: this.applications.knative.hostname,
          pages_domain_id: this.applications.knative.pagesDomain?.id,
        },
      });
    },
    setKnativeDomain({ domainId, domain }) {
      eventHub.$emit('setKnativeDomain', {
        id: 'knative',
        domainId,
        domain,
      });
    },
    setCrossplaneProviderStack(stack) {
      eventHub.$emit('setCrossplaneProviderStack', {
        id: 'crossplane',
        stack,
      });
    },
  },
  logos: {
    gitlabLogo,
    helmLogo,
    jupyterhubLogo,
    kubernetesLogo,
    certManagerLogo,
    crossplaneLogo,
    knativeLogo,
    prometheusLogo,
    elasticStackLogo,
    fluentdLogo,
  },
};
</script>

<template>
  <section id="cluster-applications">
    <p class="gl-mb-0">
      {{
        s__(`ClusterIntegration|Choose which applications to install on your Kubernetes cluster.`)
      }}
      <gl-link :href="helpPath">{{ __('More information') }}</gl-link>
    </p>

    <div class="cluster-application-list gl-mt-3">
      <application-row
        v-if="applications.helm.installed || applications.helm.uninstalling"
        id="helm"
        :logo-url="$options.logos.helmLogo"
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
        title-link="https://v2.helm.sh/"
      >
        <template #description>
          <p>
            {{
              s__(`ClusterIntegration|Can be safely removed. Prior to GitLab
              13.2, GitLab used a remote Tiller server to manage the
              applications. GitLab no longer uses this server.
              Uninstalling this server will not affect your other
              applications. This row will disappear afterwards.`)
            }}
            <gl-link :href="helmHelpPath">{{ __('More information') }}</gl-link>
          </p>
        </template>
      </application-row>
      <application-row
        :id="ingressId"
        :logo-url="$options.logos.kubernetesLogo"
        :title="applications.ingress.title"
        :status="applications.ingress.status"
        :status-reason="applications.ingress.statusReason"
        :request-status="applications.ingress.requestStatus"
        :request-reason="applications.ingress.requestReason"
        :installed="applications.ingress.installed"
        :install-failed="applications.ingress.installFailed"
        :install-application-request-params="{
          modsecurity_enabled: applications.ingress.modsecurity_enabled,
          modsecurity_mode: applications.ingress.modsecurity_mode,
        }"
        :uninstallable="applications.ingress.uninstallable"
        :uninstall-successful="applications.ingress.uninstallSuccessful"
        :uninstall-failed="applications.ingress.uninstallFailed"
        :updateable="false"
        title-link="https://kubernetes.io/docs/concepts/services-networking/ingress/"
      >
        <template #description>
          <p>
            {{
              s__(`ClusterIntegration|Ingress gives you a way to route
                        requests to services based on the request host or path,
                        centralizing a number of services into a single entrypoint.`)
            }}
          </p>

          <ingress-modsecurity-settings
            :ingress="ingress"
            :ingress-mod-security-help-path="ingressModSecurityHelpPath"
          />

          <template v-if="ingressInstalled">
            <div class="form-group">
              <label for="ingress-endpoint">{{ s__('ClusterIntegration|Ingress Endpoint') }}</label>
              <div class="input-group">
                <template v-if="ingressExternalEndpoint">
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
                </template>
                <template v-else>
                  <input type="text" class="form-control js-endpoint" readonly />
                  <gl-loading-icon
                    class="position-absolute align-self-center ml-2 js-ingress-ip-loading-icon"
                  />
                </template>
              </div>
              <p class="form-text text-muted">
                {{
                  s__(`ClusterIntegration|Point a wildcard DNS to this
                                generated endpoint in order to access
                                your application after it has been deployed.`)
                }}
                <gl-link :href="ingressDnsHelpPath" target="_blank">
                  {{ __('More information') }}
                </gl-link>
              </p>
            </div>

            <p v-if="!ingressExternalEndpoint" class="settings-message js-no-endpoint-message">
              {{
                s__(`ClusterIntegration|The endpoint is in
                            the process of being assigned. Please check your Kubernetes
                            cluster or Quotas on Google Kubernetes Engine if it takes a long time.`)
              }}
              <gl-link :href="ingressDnsHelpPath" target="_blank">
                {{ __('More information') }}
              </gl-link>
            </p>
          </template>
          <template v-else>
            <gl-alert variant="info" :dismissible="false">
              <span data-testid="ingressCostWarning">
                <gl-sprintf
                  :message="
                    s__(
                      'ClusterIntegration|Installing Ingress may incur additional costs. Learn more about %{linkStart}pricing%{linkEnd}.',
                    )
                  "
                >
                  <template #link="{ content }">
                    <gl-link href="https://cloud.google.com/compute/pricing#lb" target="_blank">{{
                      content
                    }}</gl-link>
                  </template>
                </gl-sprintf>
              </span>
            </gl-alert>
          </template>
        </template>
      </application-row>
      <application-row
        id="cert_manager"
        :logo-url="$options.logos.certManagerLogo"
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
        title-link="https://cert-manager.readthedocs.io/en/latest/#"
      >
        <template #description>
          <p data-testid="certManagerDescription">
            <gl-sprintf
              :message="
                s__(`ClusterIntegration|Cert-Manager is a native Kubernetes certificate management controller that helps with issuing certificates.
            Installing Cert-Manager on your cluster will issue a certificate by %{linkStart}Let's Encrypt%{linkEnd} and ensure that certificates
            are valid and up-to-date.`)
              "
            >
              <template #link="{ content }">
                <gl-link href="https://letsencrypt.org/" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </p>
          <div class="form-group">
            <label for="cert-manager-issuer-email">
              {{ s__('ClusterIntegration|Issuer Email') }}
            </label>
            <div class="input-group">
              <!-- eslint-disable vue/no-mutating-props -->
              <input
                id="cert-manager-issuer-email"
                v-model="applications.cert_manager.email"
                :readonly="certManagerInstalled"
                type="text"
                class="form-control js-email"
              />
              <!-- eslint-enable vue/no-mutating-props -->
            </div>
            <p class="form-text text-muted">
              {{
                s__(`ClusterIntegration|Issuers represent a certificate authority.
                              You must provide an email address for your Issuer.`)
              }}
              <gl-link
                href="http://docs.cert-manager.io/en/latest/reference/issuers.html?highlight=email"
                target="_blank"
                >{{ __('More information') }}</gl-link
              >
            </p>
          </div>
        </template>
      </application-row>
      <application-row
        id="prometheus"
        :logo-url="$options.logos.prometheusLogo"
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
        title-link="https://prometheus.io/docs/introduction/overview/"
      >
        <template #description>
          <span data-testid="prometheusDescription">
            <gl-sprintf
              :message="
                s__(`ClusterIntegration|Prometheus is an open-source monitoring system
                          with %{linkStart}GitLab Integration%{linkEnd} to monitor deployed applications.`)
              "
            >
              <template #link="{ content }">
                <gl-link
                  href="https://docs.gitlab.com/ee/user/project/integrations/prometheus.html"
                  target="_blank"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </span>
        </template>
      </application-row>
      <application-row
        id="runner"
        :logo-url="$options.logos.gitlabLogo"
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
        title-link="https://docs.gitlab.com/runner/"
      >
        <template #description>
          {{
            s__(`ClusterIntegration|GitLab Runner connects to the
                    repository and executes CI/CD jobs,
                    pushing results back and deploying
                    applications to production.`)
          }}
        </template>
      </application-row>
      <application-row
        id="crossplane"
        :logo-url="$options.logos.crossplaneLogo"
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
        title-link="https://crossplane.io"
      >
        <template #description>
          <p data-testid="crossplaneDescription">
            <gl-sprintf
              :message="
                s__(
                  `ClusterIntegration|Crossplane enables declarative provisioning of managed services from your cloud of choice using %{codeStart}kubectl%{codeEnd} or %{linkStart}GitLab Integration%{linkEnd}.
              Crossplane runs inside your Kubernetes cluster and supports secure connectivity and secrets management between app containers and the cloud services they depend on.`,
                )
              "
            >
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
              <template #link="{ content }">
                <gl-link
                  href="https://docs.gitlab.com/ee/user/clusters/applications.html#crossplane"
                  target="_blank"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </p>
          <div class="form-group">
            <CrossplaneProviderStack :crossplane="crossplane" @set="setCrossplaneProviderStack" />
          </div>
        </template>
      </application-row>

      <application-row
        id="jupyter"
        :logo-url="$options.logos.jupyterhubLogo"
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
        title-link="https://jupyterhub.readthedocs.io/en/stable/"
      >
        <template #description>
          <p>
            {{
              s__(`ClusterIntegration|JupyterHub, a multi-user Hub, spawns,
                        manages, and proxies multiple instances of the single-user
                        Jupyter notebook server. JupyterHub can be used to serve
                        notebooks to a class of students, a corporate data science group,
                        or a scientific research group.`)
            }}
            <gl-sprintf
              :message="
                s__(
                  'ClusterIntegration|%{boldStart}Note:%{boldEnd} Requires Ingress to be installed.',
                )
              "
            >
              <template #bold="{ content }">
                <b>{{ content }}</b>
              </template>
            </gl-sprintf>
          </p>

          <template v-if="ingressExternalEndpoint">
            <div class="form-group">
              <label for="jupyter-hostname">{{ s__('ClusterIntegration|Jupyter Hostname') }}</label>

              <div class="input-group">
                <!-- eslint-disable vue/no-mutating-props -->
                <input
                  id="jupyter-hostname"
                  v-model="applications.jupyter.hostname"
                  :readonly="jupyterInstalled"
                  type="text"
                  class="form-control js-hostname"
                />
                <!-- eslint-enable vue/no-mutating-props -->
                <span class="input-group-append">
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
                <gl-link :href="ingressDnsHelpPath" target="_blank">
                  {{ __('More information') }}
                </gl-link>
              </p>
            </div>
          </template>
        </template>
      </application-row>
      <application-row
        id="knative"
        :logo-url="$options.logos.knativeLogo"
        :title="applications.knative.title"
        :status="applications.knative.status"
        :status-reason="applications.knative.statusReason"
        :request-status="applications.knative.requestStatus"
        :request-reason="applications.knative.requestReason"
        :installed="applications.knative.installed"
        :install-failed="applications.knative.installFailed"
        :install-application-request-params="{
          hostname: applications.knative.hostname,
          pages_domain_id: applications.knative.pagesDomain && applications.knative.pagesDomain.id,
        }"
        :uninstallable="applications.knative.uninstallable"
        :uninstall-successful="applications.knative.uninstallSuccessful"
        :uninstall-failed="applications.knative.uninstallFailed"
        :updateable="false"
        v-bind="applications.knative"
        title-link="https://github.com/knative/docs"
      >
        <template #description>
          <gl-alert v-if="!rbac" variant="info" class="rbac-notice gl-my-3" :dismissible="false">
            {{
              s__(`ClusterIntegration|You must have an RBAC-enabled cluster
            to install Knative.`)
            }}
            <gl-link :href="helpPath" target="_blank">{{ __('More information') }}</gl-link>
          </gl-alert>
          <p>
            {{
              s__(`ClusterIntegration|Knative extends Kubernetes to provide
                        a set of middleware components that are essential to build modern,
                        source-centric, and container-based applications that can run
                        anywhere: on premises, in the cloud, or even in a third-party data center.`)
            }}
          </p>

          <knative-domain-editor
            v-if="(knative.installed || rbac) && !preInstalledKnative"
            :knative="knative"
            :ingress-dns-help-path="ingressDnsHelpPath"
            @save="saveKnativeDomain"
            @set="setKnativeDomain"
          />
        </template>
        <template v-if="cloudRun" #installed-via>
          <span data-testid="installed-via">
            <gl-sprintf
              :message="s__('ClusterIntegration|installed via %{linkStart}Cloud Run%{linkEnd}')"
            >
              <template #link="{ content }">
                <gl-link :href="cloudRunHelpPath" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </template>
      </application-row>
      <application-row
        id="elastic_stack"
        :logo-url="$options.logos.elasticStackLogo"
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
        title-link="https://gitlab.com/gitlab-org/charts/elastic-stack"
      >
        <template #description>
          <p>
            {{
              s__(
                `ClusterIntegration|The elastic stack collects logs from all pods in your cluster`,
              )
            }}
          </p>
        </template>
      </application-row>

      <application-row
        id="fluentd"
        :logo-url="$options.logos.fluentdLogo"
        :title="applications.fluentd.title"
        :status="applications.fluentd.status"
        :status-reason="applications.fluentd.statusReason"
        :request-status="applications.fluentd.requestStatus"
        :request-reason="applications.fluentd.requestReason"
        :installed="applications.fluentd.installed"
        :install-failed="applications.fluentd.installFailed"
        :install-application-request-params="{
          host: applications.fluentd.host,
          port: applications.fluentd.port,
          protocol: applications.fluentd.protocol,
          waf_log_enabled: applications.fluentd.wafLogEnabled,
          cilium_log_enabled: applications.fluentd.ciliumLogEnabled,
        }"
        :uninstallable="applications.fluentd.uninstallable"
        :uninstall-successful="applications.fluentd.uninstallSuccessful"
        :uninstall-failed="applications.fluentd.uninstallFailed"
        :updateable="false"
        title-link="https://github.com/helm/charts/tree/master/stable/fluentd"
      >
        <template #description>
          <p>
            {{
              s__(
                `ClusterIntegration|Fluentd is an open source data collector, which lets you unify the data collection and consumption for a better use and understanding of data. It requires at least one of the following logs to be successfully installed.`,
              )
            }}
          </p>

          <fluentd-output-settings
            :port="applications.fluentd.port"
            :protocol="applications.fluentd.protocol"
            :host="applications.fluentd.host"
            :waf-log-enabled="applications.fluentd.wafLogEnabled"
            :cilium-log-enabled="applications.fluentd.ciliumLogEnabled"
            :status="applications.fluentd.status"
            :update-failed="applications.fluentd.updateFailed"
          />
        </template>
      </application-row>

      <div class="gl-mt-7 gl-border-1 gl-border-t-solid gl-border-gray-100">
        <!-- This empty div serves as a separator. The applications below can be externally installed using a cluster-management project. -->
      </div>

      <application-row
        id="cilium"
        :title="applications.cilium.title"
        :logo-url="$options.logos.gitlabLogo"
        :status="applications.cilium.status"
        :status-reason="applications.cilium.statusReason"
        :installable="applications.cilium.installable"
        :uninstallable="applications.cilium.uninstallable"
        :installed="applications.cilium.installed"
        :install-failed="applications.cilium.installFailed"
        :title-link="ciliumHelpPath"
      >
        <template #description>
          <p data-testid="ciliumDescription">
            <gl-sprintf
              :message="
                s__(
                  'ClusterIntegration|Protect your clusters with GitLab Container Network Policies by enforcing how pods communicate with each other and other network endpoints. %{linkStart}Learn more about configuring Network Policies here.%{linkEnd}',
                )
              "
            >
              <template #link="{ content }">
                <gl-link :href="ciliumHelpPath" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </p>
        </template>
      </application-row>
    </div>
  </section>
</template>
