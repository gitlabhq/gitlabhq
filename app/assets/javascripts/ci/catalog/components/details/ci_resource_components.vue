<script>
import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import getCiCatalogResourceComponents from '../../graphql/queries/get_ci_catalog_resource_components.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlTableLite,
  },
  props: {
    resourceId: {
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
          id: this.resourceId,
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
    inputTitle: s__('CiCatalogComponent|Inputs'),
    fetchError: s__("CiCatalogComponent|There was an error fetching this resource's components"),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" />
    <template v-else>
      <div
        v-for="component in components"
        :key="component.id"
        class="gl-mb-8"
        data-testid="component-section"
      >
        <h3 class="gl-font-size-h2" data-testid="component-name">{{ component.name }}</h3>
        <p class="gl-mt-5">{{ component.description }}</p>
        <pre class="gl-w-85p gl-py-4">{{ generateSnippet(component.path) }}</pre>
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
