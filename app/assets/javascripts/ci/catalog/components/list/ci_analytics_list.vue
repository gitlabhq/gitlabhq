<script>
import { GlTableLite, GlBadge, GlLink, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from '~/ci/catalog/router/constants';

export default {
  name: 'CiAnalyticsList',
  components: {
    GlTableLite,
    GlBadge,
    GlLink,
    HelpIcon,
  },
  directives: {
    GlTooltip,
  },
  props: {
    resources: {
      type: Array,
      required: true,
    },
  },
  computed: {
    items() {
      return this.resources.map((resource) => {
        return {
          name: resource.name,
          detailsPath: this.getDetailsPath(resource),
          latestVersion: this.getLatestVersion(resource),
          usageStatistics: this.getUsageStatistics(resource),
          components: this.getComponents(resource),
        };
      });
    },
  },
  methods: {
    getDetailsPath(item) {
      return {
        name: CI_RESOURCE_DETAILS_PAGE_NAME,
        params: { id: item?.fullPath },
      };
    },
    getLatestVersion(item) {
      const latestVersion = item?.versions?.nodes[0] || {};
      return latestVersion?.name || s__('CiCatalog|Unreleased');
    },
    getUsageStatistics(item) {
      const usageCount = item?.last30DayUsageCount || 0;
      return n__('CiCatalog|%d project', 'CiCatalog|%d projects', usageCount);
    },
    getComponents(item) {
      const components = item?.versions?.nodes[0]?.components?.nodes || [];
      return components.map((component) => component.name).join(', ');
    },
  },
  fields: [
    {
      key: 'projects',
      label: s__('CiCatalog|Projects'),
    },
    {
      key: 'usageStatistics',
      label: s__('CiCatalog|Usage statistics'),
    },
    {
      key: 'components',
      label: s__('CiCatalog|Components'),
      tdClass: '!gl-text-secondary',
    },
  ],
};
</script>
<template>
  <gl-table-lite :items="items" :fields="$options.fields" stacked="md" fixed>
    <template #head(usageStatistics)="{ label }">
      <span>{{ label }}</span>
      <help-icon
        v-gl-tooltip
        class="gl-ml-2"
        :title="
          s__(
            'CiCatalog|The number of unique projects that used a component from this catalog project in a pipeline in the last 30 days.',
          )
        "
      />
    </template>

    <template #cell(projects)="{ item }">
      <gl-link :to="item.detailsPath" class="!gl-text-default">{{ item.name }}</gl-link>
      <gl-badge variant="info">{{ item.latestVersion }}</gl-badge>
    </template>
  </gl-table-lite>
</template>
