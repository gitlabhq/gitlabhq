<script>
import {
  GlFormGroup,
  GlCollapsibleListbox,
  GlAlert,
  GlTooltipDirective,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import fluxKustomizationsQuery from '../graphql/queries/flux_kustomizations.query.graphql';
import fluxHelmReleasesQuery from '../graphql/queries/flux_helm_releases.query.graphql';
import discoverFluxKustomizationsQuery from '../graphql/queries/discover_flux_kustomizations.query.graphql';
import discoverFluxHelmReleasesQuery from '../graphql/queries/discover_flux_helm_releases.query.graphql';
import {
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
  KUSTOMIZATION,
  HELM_RELEASE,
  SUPPORTED_HELM_RELEASES,
  SUPPORTED_KUSTOMIZATIONS,
} from '../constants';

export default {
  components: {
    GlFormGroup,
    GlCollapsibleListbox,
    GlAlert,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: false,
      type: String,
      default: '',
    },
    fluxResourcePath: {
      required: false,
      type: String,
      default: '',
    },
  },
  data() {
    return {
      fluxResourceSearchTerm: '',
      kustomizationsError: '',
      helmReleasesError: '',
      discoverError: false,
      fluxKustomizations: [],
      fluxHelmReleases: [],
      discoverFluxKustomizations: {},
      discoverFluxHelmReleases: {},
    };
  },
  apollo: {
    discoverFluxKustomizations: {
      query: discoverFluxKustomizationsQuery,
      variables() {
        return { configuration: this.configuration };
      },
      skip() {
        return !this.namespace;
      },
      update(data) {
        return data?.discoverFluxKustomizations || {};
      },
      error() {
        this.discoverError = true;
      },
    },
    fluxKustomizations: {
      query: fluxKustomizationsQuery,
      variables() {
        return { ...this.variables, version: this.kustomizationsVersion };
      },
      skip() {
        return !this.namespace || !this.kustomizationsVersion;
      },
      update(data) {
        return data?.fluxKustomizations || [];
      },
      error() {
        this.kustomizationsError = KUSTOMIZATION;
      },
      result(result) {
        if (!result?.error && !result.errors?.length) {
          this.kustomizationsError = '';
        }
      },
    },
    discoverFluxHelmReleases: {
      query: discoverFluxHelmReleasesQuery,
      variables() {
        return { configuration: this.configuration };
      },
      skip() {
        return !this.namespace;
      },
      update(data) {
        return data?.discoverFluxHelmReleases || {};
      },
      error() {
        this.discoverError = true;
      },
    },
    fluxHelmReleases: {
      query: fluxHelmReleasesQuery,
      variables() {
        return { ...this.variables, version: this.helmReleasesVersion };
      },
      skip() {
        return !this.namespace || !this.helmReleasesVersion;
      },
      update(data) {
        return data?.fluxHelmReleases || [];
      },
      error() {
        this.helmReleasesError = HELM_RELEASE;
      },
      result(result) {
        if (!result?.error && !result.errors?.length) {
          this.helmReleasesError = '';
        }
      },
    },
  },
  computed: {
    variables() {
      return {
        configuration: this.configuration,
        namespace: this.namespace,
      };
    },
    kustomizationsVersion() {
      if (this.$apollo.queries.discoverFluxKustomizations.loading) return null;
      return this.discoverFluxKustomizations.supportedVersion || SUPPORTED_KUSTOMIZATIONS[0];
    },
    helmReleasesVersion() {
      if (this.$apollo.queries.discoverFluxHelmReleases.loading) return null;
      return this.discoverFluxHelmReleases.supportedVersion || SUPPORTED_HELM_RELEASES[0];
    },
    unsupportedVersions() {
      const items = [];
      const resources = [this.discoverFluxKustomizations, this.discoverFluxHelmReleases];

      for (const data of resources) {
        if (data.preferredVersion && data.preferredVersion !== data.supportedVersion) {
          items.push({
            preferredVersion: data.preferredVersion,
            supportedVersion: data.supportedVersion || null,
          });
        }
      }

      return items;
    },
    loadingFluxResourcesList() {
      return this.$apollo.loading;
    },
    kubernetesErrors() {
      const errors = [];
      if (this.kustomizationsError) {
        errors.push(this.kustomizationsError);
      }
      if (this.helmReleasesError) {
        errors.push(this.helmReleasesError);
      }
      return errors;
    },
    fluxResourcesDropdownToggleText() {
      const selectedResourceParts = this.fluxResourcePath ? this.fluxResourcePath.split('/') : [];
      return selectedResourceParts.length
        ? selectedResourceParts.at(-1)
        : s__('Environments|Select Flux resource');
    },
    fluxKustomizationsList() {
      return (
        this.fluxKustomizations?.map((item) => {
          return {
            value: `${item.apiVersion}/namespaces/${item.metadata.namespace}/${KUSTOMIZATIONS_RESOURCE_TYPE}/${item.metadata.name}`,
            text: item.metadata.name,
          };
        }) || []
      );
    },
    fluxHelmReleasesList() {
      return (
        this.fluxHelmReleases?.map((item) => {
          return {
            value: `${item.apiVersion}/namespaces/${item.metadata.namespace}/${HELM_RELEASES_RESOURCE_TYPE}/${item.metadata.name}`,
            text: item.metadata.name,
          };
        }) || []
      );
    },
    filteredKustomizationsList() {
      const lowerCasedSearchTerm = this.fluxResourceSearchTerm.toLowerCase();
      return this.fluxKustomizationsList.filter((item) =>
        item.text.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    filteredHelmResourcesList() {
      const lowerCasedSearchTerm = this.fluxResourceSearchTerm.toLowerCase();
      return this.fluxHelmReleasesList.filter((item) =>
        item.text.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    fluxResourcesList() {
      const list = [];
      if (this.filteredKustomizationsList?.length) {
        list.push({
          text: s__('Environments|Kustomizations'),
          options: this.filteredKustomizationsList,
        });
      }

      if (this.filteredHelmResourcesList?.length) {
        list.push({
          text: s__('Environments|HelmReleases'),
          options: this.filteredHelmResourcesList,
        });
      }
      return list;
    },
    isDisabled() {
      return !this.namespace;
    },
  },
  methods: {
    onChange(event) {
      this.$emit('change', event);
    },
    onSearch(search) {
      this.fluxResourceSearchTerm = search;
    },
  },
  requestIssueUrl: 'https://gitlab.com/gitlab-org/gitlab/-/issues/584823',
  apiDocUrl: helpPagePath('api/environments.md', { anchor: 'update-an-existing-environment' }),
};
</script>
<template>
  <gl-form-group
    :description="
      s__(
        'Environments|If a Flux resource is specified, its reconciliation status is reflected in GitLab.',
      )
    "
    :label="s__('Environments|Select Flux resource (optional)')"
    label-for="environment_flux_resource"
  >
    <gl-alert
      v-if="kubernetesErrors.length || unsupportedVersions.length || discoverError"
      variant="warning"
      :dismissible="false"
      class="gl-mb-5"
    >
      <template v-if="kubernetesErrors.length">
        {{
          s__(
            'Environments|Unable to access the following resources from this environment. Check your authorization on the following and try again:',
          )
        }}
        <ul class="gl-pl-6" :class="{ 'gl-mb-0': !unsupportedVersions.length }">
          <li v-for="(error, index) of kubernetesErrors" :key="index">{{ error }}</li>
        </ul>
      </template>

      <template v-if="discoverError">
        {{ s__('Environments|Unable to discover supported Flux resource versions.') }}
      </template>

      <template v-if="unsupportedVersions.length">
        {{ s__('Environments|The preferred version of your resource is not supported:') }}
        <ul class="gl-mb-3 gl-pl-6">
          <li v-for="(item, index) in unsupportedVersions" :key="index">
            {{ item.preferredVersion }}
            <gl-sprintf
              v-if="item.supportedVersion"
              :message="s__('Environments|(available version - %{version})')"
            >
              <template #version>{{ item.supportedVersion }}</template>
            </gl-sprintf>
          </li>
        </ul>

        <gl-sprintf
          :message="
            s__(
              'Environments|%{requestLinkStart}Request version support%{requestLinkEnd} or %{apiLinkStart}use API%{apiLinkEnd} to set resource path.',
            )
          "
        >
          <template #requestLink="{ content }"
            ><gl-link :href="$options.requestIssueUrl" data-testid="request-version-support-link">{{
              content
            }}</gl-link></template
          >
          <template #apiLink="{ content }"
            ><gl-link :href="$options.apiDocUrl" data-testid="api-docs-link">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </gl-alert>

    <gl-collapsible-listbox
      id="environment_flux_resource_path"
      v-gl-tooltip.hover.top="{
        title: isDisabled
          ? s__('Environments|Select a namespace to see available Flux resources.')
          : '',
      }"
      class="gl-w-full"
      block
      :disabled="isDisabled"
      :selected="fluxResourcePath"
      :items="fluxResourcesList"
      :loading="loadingFluxResourcesList"
      :toggle-text="fluxResourcesDropdownToggleText"
      :header-text="s__('Environments|Select Flux resource')"
      :reset-button-label="__('Reset')"
      searchable
      @search="onSearch"
      @select="onChange"
      @reset="onChange(null)"
    />
  </gl-form-group>
</template>
