<script>
import {
  GlButton,
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTableLite,
  GlTruncate,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import PageNavigationMenu from '~/vue_shared/components/page_navigation_menu.vue';
import getCiCatalogResourceComponents from '../../graphql/queries/get_ci_catalog_resource_components.query.graphql';

export default {
  name: 'CiResourceComponents',
  components: {
    GlButton,
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTableLite,
    GlTruncate,
    HelpIcon,
    PageNavigationMenu,
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
      result() {
        this.$nextTick(() => {
          if (window.location.hash) {
            const componentName = decodeURIComponent(window.location.hash.substring(1));
            this.scrollToComponent(componentName);
          }
        });
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
    navigationItems() {
      return this.components.map((component) => ({
        id: encodeURIComponent(component.name),
        label: component.name,
      }));
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
    getComponentLabel(componentName) {
      return sprintf(s__('CiCatalogComponent|Link to %{componentName}'), { componentName });
    },
    scrollToComponent(componentName) {
      const hash = `#${encodeURIComponent(componentName)}`;
      window.history.pushState(null, '', hash);
      const element = document.getElementById(encodeURIComponent(componentName));
      if (element) {
        scrollToElement(element, { behavior: 'smooth' });
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
    <div v-else class="gl-flex gl-gap-6">
      <div class="gl-flex-grow-1 gl-min-w-0">
        <div
          v-for="component in components"
          :id="encodeURIComponent(component.name)"
          :key="component.id"
          class="gl-mb-8 gl-scroll-mt-8"
          data-testid="component-section"
        >
          <h3 class="gl-group gl-mt-0 gl-text-size-h2" data-testid="component-name">
            {{ component.name }}
            <gl-button
              :href="`#${encodeURIComponent(component.name)}`"
              class="gl-invisible gl-ml-2 !gl-text-subtle group-hover:gl-visible"
              :aria-label="getComponentLabel(component.name)"
              icon="link"
              variant="link"
              @click.prevent="scrollToComponent(component.name)"
            />
            <span
              v-gl-tooltip.top
              data-testid="usage-count"
              :title="
                s__(
                  'CiCatalogComponent|The number of projects that used this version of the component in the last 30 days.',
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
                data-testid="input-help-link"
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
      </div>
      <div class="gl-w-64 gl-hidden gl-flex-shrink-0 @lg/panel:gl-block">
        <page-navigation-menu :items="navigationItems" />
      </div>
    </div>
  </div>
</template>
