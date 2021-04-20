<script>
import { s__ } from '~/locale';
import ReportItem from '~/reports/components/report_item.vue';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';

export default {
  components: {
    ReportItem,
    SmartVirtualList,
  },
  props: {
    component: {
      type: String,
      required: false,
      default: '',
    },
    nestedLevel: {
      type: Number,
      required: false,
      default: 0,
      validator: (value) => [0, 1, 2].includes(value),
    },
    resolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    unresolvedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    resolvedHeading: {
      type: String,
      required: false,
      default: s__('ciReport|Fixed'),
    },
    unresolvedHeading: {
      type: String,
      required: false,
      default: s__('ciReport|New'),
    },
  },
  groups: ['unresolved', 'resolved'],
  typicalReportItemHeight: 32,
  maxShownReportItems: 20,
  computed: {
    groups() {
      return this.$options.groups
        .map((group) => ({
          name: group,
          issues: this[`${group}Issues`],
          heading: this[`${group}Heading`],
        }))
        .filter(({ issues }) => issues.length > 0);
    },
    listLength() {
      // every group has a header which is rendered as a list item
      const groupsCount = this.groups.length;
      const issuesCount = this.groups.reduce(
        (totalIssues, { issues }) => totalIssues + issues.length,
        0,
      );

      return groupsCount + issuesCount;
    },
    listClasses() {
      return {
        'gl-pl-9': this.nestedLevel === 1,
        'gl-pl-11-5': this.nestedLevel === 2,
      };
    },
  },
};
</script>

<template>
  <smart-virtual-list
    :length="listLength"
    :remain="$options.maxShownReportItems"
    :size="$options.typicalReportItemHeight"
    :class="listClasses"
    class="report-block-container"
    wtag="ul"
    wclass="report-block-list"
  >
    <template v-for="(group, groupIndex) in groups">
      <h2
        :key="group.name"
        :data-testid="`${group.name}Heading`"
        :class="[groupIndex > 0 ? 'mt-2' : 'mt-0']"
        class="h5 mb-1"
      >
        {{ group.heading }}
      </h2>
      <report-item
        v-for="(issue, issueIndex) in group.issues"
        :key="`${group.name}-${issue.name}-${group.name}-${issueIndex}`"
        :issue="issue"
        :show-report-section-status-icon="false"
        :component="component"
        status="none"
      />
    </template>
  </smart-virtual-list>
</template>
