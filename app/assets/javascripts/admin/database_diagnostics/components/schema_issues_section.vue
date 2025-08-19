<script>
import { GlAlert, GlButton, GlIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'SchemaIssuesSection',
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlBadge,
  },
  props: {
    databaseResults: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      expandedSections: {},
    };
  },
  computed: {
    sectionConfigs() {
      return [
        {
          key: 'indexes',
          title: s__('DatabaseDiagnostics|Indexes'),
          issues: this.databaseResults.missing_indexes || [],
          icon: 'search',
        },
        {
          key: 'tables',
          title: s__('DatabaseDiagnostics|Tables'),
          issues: this.databaseResults.missing_tables || [],
          icon: 'table',
        },
        {
          key: 'foreignKeys',
          title: s__('DatabaseDiagnostics|Foreign keys'),
          issues: this.databaseResults.missing_foreign_keys || [],
          icon: 'link',
        },
        {
          key: 'sequences',
          title: s__('DatabaseDiagnostics|Sequences'),
          issues: this.databaseResults.missing_sequences || [],
          icon: 'list-numbered',
        },
      ];
    },
    totalIssuesCount() {
      return this.sectionConfigs.reduce((total, section) => total + section.issues.length, 0);
    },
  },
  methods: {
    toggleSection(sectionKey) {
      this.expandedSections = {
        ...this.expandedSections,
        [sectionKey]: !this.expandedSections[sectionKey],
      };
    },
    getSectionIcon(section) {
      return {
        name: section.issues.length > 0 ? 'warning' : 'check-circle-filled',
        class: section.issues.length > 0 ? 'gl-text-orange-500' : 'gl-text-green-500',
      };
    },
  },
};
</script>

<template>
  <div>
    <!-- Overall Status -->
    <div v-if="totalIssuesCount === 0" class="gl-mb-4">
      <gl-alert variant="success" :dismissible="false" data-testid="no-issues-alert">
        <gl-icon name="check-circle-filled" class="gl-mr-2 gl-text-green-500" />
        {{ s__('DatabaseDiagnostics|No schema issues detected.') }}
      </gl-alert>
    </div>

    <!-- Individual Sections -->
    <div v-for="section in sectionConfigs" :key="section.key" class="gl-mb-4">
      <div class="gl-flex gl-items-center gl-justify-between gl-rounded-base gl-bg-gray-50 gl-p-3">
        <div class="gl-flex gl-items-center">
          <gl-icon v-bind="getSectionIcon(section)" class="gl-mr-2" />
          <strong>{{ section.title }}</strong>
          <gl-badge
            v-if="section.issues.length > 0"
            variant="warning"
            class="gl-ml-2"
            :data-testid="`${section.key}-count`"
          >
            {{ section.issues.length }}
          </gl-badge>
        </div>

        <gl-button
          v-if="section.issues.length > 0"
          category="tertiary"
          size="small"
          :data-testid="`${section.key}-toggle`"
          @click="toggleSection(section.key)"
        >
          <gl-icon
            :name="expandedSections[section.key] ? 'chevron-up' : 'chevron-down'"
            :size="14"
            class="gl-mr-2"
          />
          {{ s__('DatabaseDiagnostics|Details') }}
        </gl-button>
      </div>

      <!-- Expanded Issues List -->
      <div
        v-if="expandedSections[section.key] && section.issues.length > 0"
        class="gl-mt-2 gl-rounded-base gl-border-1 gl-border-solid gl-border-orange-200 gl-bg-orange-50 gl-p-3"
        :data-testid="`${section.key}-issues`"
      >
        <div class="gl-mb-2">
          <gl-icon name="warning" :size="14" class="gl-mr-2 gl-text-orange-500" />
          <strong class="gl-text-sm gl-text-gray-700">
            {{ s__('DatabaseDiagnostics|Missing items') }}
          </strong>
        </div>

        <div class="gl-pl-5">
          <div
            v-for="(issue, index) in section.issues"
            :key="index"
            class="gl-mb-2 gl-flex gl-items-center gl-text-sm last:gl-mb-0"
          >
            <gl-icon
              name="dash"
              :size="12"
              class="gl-mr-2 gl-mt-1 gl-flex-shrink-0 gl-text-gray-500"
            />
            <span class="gl-flex-grow">
              <template v-if="typeof issue === 'object'">
                <strong v-if="issue.table_name">{{ issue.table_name }}</strong>
                <span v-if="issue.column_name">: {{ issue.column_name }}</span>
                <span v-if="issue.index_name"> ({{ issue.index_name }})</span>
                <span v-if="issue.referenced_table"> → {{ issue.referenced_table }}</span>
              </template>
              <template v-else>
                {{ issue }}
              </template>
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
