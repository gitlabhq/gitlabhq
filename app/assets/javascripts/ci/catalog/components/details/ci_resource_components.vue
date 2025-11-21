<script>
import {
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTableLite,
  GlTruncate,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import getCiCatalogResourceComponents from '../../graphql/queries/get_ci_catalog_resource_components.query.graphql';

export default {
  name: 'CiResourceComponents',
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTableLite,
    GlTruncate,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inputHelpLink: helpPagePath('ci/inputs/_index.md', {
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
    getItemValue(item) {
      return String(item.default);
    },
    shouldShowCodeBlock(item) {
      return item.default && item.type === 'ARRAY';
    },
    getCodeBlock(item) {
      try {
        return JSON.stringify(item.default, null, 2);
      } catch (e) {
        return String(item.default);
      }
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
      class: '@md/panel:gl-w-15',
    },
    {
      key: 'type',
      label: s__('CiCatalogComponent|Type'),
      class: '@md/panel:gl-w-15',
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
          <span
            v-gl-tooltip.top
            data-testid="usage-count"
            :title="
              s__(
                'CiCatalogComponent|The number of projects that used the component in the last 30 days.',
              )
            "
            class="gl-ml-2 gl-text-sm gl-font-normal gl-text-subtle"
          >
            <gl-icon name="chart" />
            <span class="gl-ml-1">{{ component.last30DayUsageCount }}</span>
          </span>
        </h3>
        <pre
          data-testid="copy-to-clipboard"
          class="code highlight js-syntax-highlight language-yaml"
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
          <gl-table-lite :items="component.inputs" :fields="$options.fields" stacked="md" fixed>
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
              <span data-testid="input-description" class="gl-break-words">{{
                item.description
              }}</span>
            </template>
            <template #cell(default)="{ item }">
              <pre
                v-if="shouldShowCodeBlock(item)"
                class="gl-text-left gl-text-sm"
                data-testid="input-code-block"
                >{{ getCodeBlock(item) }}</pre
              >
              <code v-else-if="getItemValue(item)" data-testid="input-default">
                <gl-truncate
                  :text="getItemValue(item)"
                  position="end"
                  class="gl-max-w-full"
                  with-tooltip
                />
              </code>
            </template>
          </gl-table-lite>
        </div>
      </div>
    </template>
  </div>
</template>
