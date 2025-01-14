<script>
import { GlEmptyState, GlLink, GlLoadingIcon, GlTableLite, GlTruncate } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import getCiCatalogResourceComponents from '../../graphql/queries/get_ci_catalog_resource_components.query.graphql';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    GlTableLite,
    GlTruncate,
    HelpIcon,
  },
  inputHelpLink: helpPagePath('ci/yaml/inputs', {
    anchor: 'define-input-parameters-with-specinputs',
  }),
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
        return data?.ciCatalogResource?.versions?.nodes[0]?.components?.nodes || [];
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
  },
  fields: [
    {
      key: 'name',
      label: s__('CiCatalogComponent|Name'),
    },
    {
      key: 'required',
      label: s__('CiCatalogComponent|Mandatory'),
    },
    {
      key: 'type',
      label: s__('CiCatalogComponent|Type'),
    },
    {
      key: 'description',
      label: s__('CiCatalogComponent|Description'),
    },
    {
      key: 'default',
      label: s__('CiCatalogComponent|Default'),
    },
  ],
  i18n: {
    emptyStateTitle: s__('CiCatalogComponent|Component details not available'),
    emptyStateDesc: s__(
      'CiCatalogComponent|This tab displays auto-collected information about the components in the repository, but no information was found.',
    ),
    fetchError: s__("CiCatalogComponent|There was an error fetching this resource's components"),
    inputTitle: s__('CiCatalogComponent|Inputs'),
    learnMore: __('Learn more'),
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
        <h3 class="gl-mt-0 gl-text-size-h2" data-testid="component-name">
          {{ component.name }}
        </h3>
        <pre
          data-testid="copy-to-clipboard"
          class="code highlight js-syntax-highlight language-yaml"
          lang="yaml"
        ><code>{{
          generateSnippet(component.includePath)
        }}</code></pre>
        <div class="gl-mt-5">
          <div class="gl-mb-4 gl-flex gl-gap-2">
            <b> {{ $options.i18n.inputTitle }}</b>
            <gl-link
              :title="$options.i18n.learnMore"
              :href="$options.inputHelpLink"
              target="_blank"
            >
              <help-icon />
            </gl-link>
          </div>
          <gl-table-lite :items="component.inputs" :fields="$options.fields">
            <template #cell(name)="{ item }">
              <code v-if="item.name" data-testid="input-name">{{ item.name }}</code>
            </template>
            <template #cell(required)="{ item }">
              <span data-testid="input-required">{{ item.required }}</span>
            </template>
            <template #cell(type)="{ item }">
              <span data-testid="input-type">{{ item.type.toLowerCase() }}</span>
            </template>
            <template #cell(description)="{ item }">
              <span data-testid="input-description">{{ item.description }}</span>
            </template>
            <template #cell(default)="{ item }">
              <code v-if="item.default" data-testid="input-default">
                <gl-truncate :text="item.default" position="end" class="gl-max-w-34" with-tooltip />
              </code>
            </template>
          </gl-table-lite>
        </div>
      </div>
    </template>
  </div>
</template>
