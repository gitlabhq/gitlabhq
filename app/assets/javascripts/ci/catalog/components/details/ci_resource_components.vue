<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import getCiCatalogResourceComponents from '../../graphql/queries/get_ci_catalog_resource_components.query.graphql';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
    GlTableLite,
  },
  props: {
    resourcePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      components: [],
    };
  },
  apollo: {
    components: {
      query: getCiCatalogResourceComponents,
      variables() {
        return {
          fullPath: this.resourcePath,
        };
      },
      update(data) {
        return data?.ciCatalogResource?.components?.nodes || [];
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  computed: {
    isMetadataMissing() {
      return !this.components || this.components?.length === 0;
    },
    isLoading() {
      return this.$apollo.queries.components.loading;
    },
  },
  methods: {
    generateSnippet(componentPath) {
      // This is not to be translated because it is our CI yaml syntax.
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `include:
  - component: ${componentPath}`;
    },
    humanizeBoolean(bool) {
      return bool ? __('Yes') : __('No');
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('CiCatalogComponent|Parameters'),
      thClass: 'gl-w-40p',
    },
    {
      key: 'defaultValue',
      label: s__('CiCatalogComponent|Default Value'),
      thClass: 'gl-w-40p',
    },
    {
      key: 'required',
      label: s__('CiCatalogComponent|Mandatory'),
      thClass: 'gl-w-20p',
    },
  ],
  i18n: {
    copyText: __('Copy value'),
    copyAriaText: __('Copy to clipboard'),
    emptyStateTitle: s__('CiCatalogComponent|Component details not available'),
    emptyStateDesc: s__(
      'CiCatalogComponent|This tab displays auto-collected information about the components in the repository, but no information was found.',
    ),
    inputTitle: s__('CiCatalogComponent|Inputs'),
    fetchError: s__("CiCatalogComponent|There was an error fetching this resource's components"),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" />
    <gl-empty-state
      v-else-if="isMetadataMissing"
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.emptyStateDesc"
    />
    <template v-else>
      <div
        v-for="component in components"
        :key="component.id"
        class="gl-mb-8"
        data-testid="component-section"
      >
        <h3 class="gl-font-size-h2" data-testid="component-name">{{ component.name }}</h3>
        <p class="gl-mt-5">{{ component.description }}</p>
        <div class="gl-display-flex">
          <pre
            class="gl-w-85p gl-py-4 gl-display-flex gl-justify-content-space-between gl-m-0 gl-border-r-none"
          ><span>{{ generateSnippet(component.path) }}</span>
        </pre>
          <div class="gl--flex-center gl-bg-gray-10 gl-border gl-border-l-none">
            <gl-button
              class="gl-p-4! gl-mr-3!"
              category="tertiary"
              icon="copy-to-clipboard"
              size="small"
              :title="$options.i18n.copyText"
              :data-clipboard-text="generateSnippet(component.path)"
              data-testid="copy-to-clipboard"
              :aria-label="$options.i18n.copyAriaText"
            />
          </div>
        </div>
        <div class="gl-mt-5">
          <b class="gl-display-block gl-mb-4"> {{ $options.i18n.inputTitle }}</b>
          <gl-table-lite :items="component.inputs.nodes" :fields="$options.fields">
            <template #cell(required)="{ item }">
              {{ humanizeBoolean(item.required) }}
            </template>
          </gl-table-lite>
        </div>
      </div>
    </template>
  </div>
</template>
