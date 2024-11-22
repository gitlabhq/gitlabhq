<script>
import { GlFormGroup, GlCollapsibleListbox, GlAlert, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import fluxKustomizationsQuery from '../graphql/queries/flux_kustomizations.query.graphql';
import fluxHelmReleasesQuery from '../graphql/queries/flux_helm_releases.query.graphql';
import {
  HELM_RELEASES_RESOURCE_TYPE,
  KUSTOMIZATIONS_RESOURCE_TYPE,
  KUSTOMIZATION,
  HELM_RELEASE,
} from '../constants';

export default {
  components: {
    GlFormGroup,
    GlCollapsibleListbox,
    GlAlert,
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
  i18n: {
    fluxResourceLabel: s__('Environments|Select Flux resource (optional)'),
    kustomizationsGroupLabel: s__('Environments|Kustomizations'),
    helmReleasesGroupLabel: s__('Environments|HelmReleases'),
    fluxResourcesHelpText: s__('Environments|Select Flux resource'),
    fluxResourceSelectorDescription: s__(
      'Environments|If a Flux resource is specified, its reconciliation status is reflected in GitLab.',
    ),
    errorTitle: s__(
      'Environments|Unable to access the following resources from this environment. Check your authorization on the following and try again:',
    ),
    reset: __('Reset'),
    tooltipTitle: s__('Environments|Select a namespace to see available Flux resources.'),
  },
  data() {
    return {
      fluxResourceSearchTerm: '',
      kustomizationsError: '',
      helmReleasesError: '',
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    fluxKustomizations: {
      query: fluxKustomizationsQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      skip() {
        return !this.namespace;
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    fluxHelmReleases: {
      query: fluxHelmReleasesQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      skip() {
        return !this.namespace;
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
        : this.$options.i18n.fluxResourcesHelpText;
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
          text: this.$options.i18n.kustomizationsGroupLabel,
          options: this.filteredKustomizationsList,
        });
      }

      if (this.filteredHelmResourcesList?.length) {
        list.push({
          text: this.$options.i18n.helmReleasesGroupLabel,
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
};
</script>
<template>
  <gl-form-group
    :description="$options.i18n.fluxResourceSelectorDescription"
    :label="$options.i18n.fluxResourceLabel"
    label-for="environment_flux_resource"
  >
    <gl-alert v-if="kubernetesErrors.length" variant="warning" :dismissible="false" class="gl-mb-5">
      {{ $options.i18n.errorTitle }}
      <ul class="gl-mb-0 gl-pl-6">
        <li v-for="(error, index) of kubernetesErrors" :key="index">{{ error }}</li>
      </ul>
    </gl-alert>

    <gl-collapsible-listbox
      id="environment_flux_resource_path"
      v-gl-tooltip.hover.top="{
        title: isDisabled ? $options.i18n.tooltipTitle : '',
      }"
      class="gl-w-full"
      block
      :disabled="isDisabled"
      :selected="fluxResourcePath"
      :items="fluxResourcesList"
      :loading="loadingFluxResourcesList"
      :toggle-text="fluxResourcesDropdownToggleText"
      :header-text="$options.i18n.fluxResourcesHelpText"
      :reset-button-label="$options.i18n.reset"
      searchable
      @search="onSearch"
      @select="onChange"
      @reset="onChange(null)"
    />
  </gl-form-group>
</template>
