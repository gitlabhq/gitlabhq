<script>
import {
  GlFormGroup,
  GlCollapsibleListbox,
  GlAlert,
  GlButton,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import getNamespacesQuery from '../graphql/queries/k8s_namespaces.query.graphql';

export default {
  components: {
    GlFormGroup,
    GlCollapsibleListbox,
    GlAlert,
    GlButton,
    GlSprintf,
    GlLink,
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
  },
  clustersHelpPagePath: helpPagePath('user/clusters/agent/_index.md'),
  i18n: {
    namespaceLabel: s__('Environments|Kubernetes namespace (optional)'),
    namespaceHelpText: s__('Environments|Select namespace'),
    selectButton: s__('Environments|Or select namespace: %{searchTerm}'),
    namespaceSelectorDescription: s__(
      'Environments|No selection shows all authorized resources in the cluster. %{linkStart}Learn more.%{linkEnd}',
    ),
    reset: __('Reset'),
  },
  data() {
    return {
      k8sNamespaces: [],
      searchTerm: '',
      kubernetesError: '',
    };
  },
  apollo: {
    k8sNamespaces: {
      query: getNamespacesQuery,

      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sNamespaces?.map((item) => {
            return {
              value: item.metadata.name,
              text: item.metadata.name,
            };
          }) || []
        );
      },
      error(error) {
        this.kubernetesError = error.message;
      },
      result(result) {
        if (!result?.error && !result.errors?.length) {
          this.kubernetesError = null;
        }
      },
    },
  },
  computed: {
    loadingNamespacesList() {
      return this.$apollo.queries.k8sNamespaces.loading;
    },
    filteredNamespacesList() {
      const lowerCasedSearchTerm = this.searchTerm.toLowerCase();
      return this.k8sNamespaces.filter((item) =>
        item.text.toLowerCase().includes(lowerCasedSearchTerm),
      );
    },
    namespaceDropdownToggleText() {
      return this.namespace || this.$options.i18n.namespaceHelpText;
    },
    shouldRenderSelectButton() {
      const hasSearchedItem = this.k8sNamespaces.some(
        (item) => item.text === this.searchTerm.toLowerCase(),
      );
      return this.searchTerm && !hasSearchedItem;
    },
  },
  methods: {
    onChange(namespace) {
      this.$emit('change', namespace);
    },
    onNamespaceSearch(search) {
      this.searchTerm = search;
    },
    onSelect(namespace) {
      this.onChange(namespace);
      this.$refs.namespaceSelector.close();
    },
  },
};
</script>
<template>
  <gl-form-group :label="$options.i18n.namespaceLabel" label-for="environment_namespace">
    <gl-alert v-if="kubernetesError" variant="warning" :dismissible="false" class="gl-mb-5">
      {{ kubernetesError }}
    </gl-alert>
    <gl-collapsible-listbox
      id="environment_namespace"
      ref="namespaceSelector"
      :selected="namespace"
      class="gl-w-full"
      block
      :items="filteredNamespacesList"
      :loading="loadingNamespacesList"
      :toggle-text="namespaceDropdownToggleText"
      :header-text="$options.i18n.namespaceHelpText"
      :reset-button-label="$options.i18n.reset"
      :searchable="true"
      @search="onNamespaceSearch"
      @select="onChange"
      @reset="onChange(null)"
    >
      <template v-if="shouldRenderSelectButton" #footer>
        <gl-button
          category="tertiary"
          class="!gl-justify-start !gl-rounded-tl-none !gl-rounded-tr-none !gl-border-t-1 gl-border-t-dropdown !gl-pl-7 gl-border-t-solid"
          :class="{ 'gl-mt-3': !filteredNamespacesList.length }"
          @click="onSelect(searchTerm)"
        >
          <gl-sprintf :message="$options.i18n.selectButton">
            <template #searchTerm>{{ searchTerm }}</template>
          </gl-sprintf>
        </gl-button>
      </template>
    </gl-collapsible-listbox>
    <template #description>
      <gl-sprintf :message="$options.i18n.namespaceSelectorDescription">
        <template #link="{ content }">
          <gl-link :href="$options.clustersHelpPagePath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-form-group>
</template>
