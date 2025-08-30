<script>
import { GlAlert, GlButton, GlIcon, GlBadge, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'SchemaIssuesSection',
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlBadge,
    GlTable,
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
          issueLabel: s__('DatabaseDiagnostics|Missing items'),
        },
        {
          key: 'tables',
          title: s__('DatabaseDiagnostics|Tables'),
          issues: this.databaseResults.missing_tables || [],
          icon: 'table',
          issueLabel: s__('DatabaseDiagnostics|Missing items'),
        },
        {
          key: 'foreignKeys',
          title: s__('DatabaseDiagnostics|Foreign keys'),
          issues: this.databaseResults.missing_foreign_keys || [],
          icon: 'link',
          issueLabel: s__('DatabaseDiagnostics|Missing items'),
        },
        {
          key: 'sequences',
          title: s__('DatabaseDiagnostics|Sequences'),
          icon: 'list-numbered',
          // Combined issues from both subsections
          issues: [
            ...(this.databaseResults.missing_sequences || []),
            ...(this.databaseResults.wrong_sequence_owners || []),
          ],
          subsections: [
            {
              key: 'missing-sequences',
              title: s__('DatabaseDiagnostics|Missing sequences'),
              issues: this.databaseResults.missing_sequences || [],
              issueLabel: s__('DatabaseDiagnostics|Missing items'),
              renderType: 'list',
            },
            {
              key: 'sequence-ownership',
              title: s__('DatabaseDiagnostics|Incorrect ownership'),
              issues: this.databaseResults.wrong_sequence_owners || [],
              issueLabel: s__('DatabaseDiagnostics|Ownership issues'),
              renderType: 'table',
            },
          ],
        },
      ];
    },
    totalIssuesCount() {
      return this.sectionConfigs.reduce((total, section) => total + section.issues.length, 0);
    },
    sequenceOwnershipTableFields() {
      return [
        {
          key: 'sequence_name',
          label: s__('DatabaseDiagnostics|Sequence Name'),
          sortable: false,
          thClass: 'gl-w-2/4 gl-min-w-32 !gl-text-sm gl-font-weight-semibold gl-text-gray-900',
          tdClass: 'gl-break-words gl-max-w-0 !gl-text-sm',
        },
        {
          key: 'current_owner',
          label: s__('DatabaseDiagnostics|Current Owner'),
          sortable: false,
          thClass: 'gl-w-1/4 gl-min-w-24 !gl-text-sm gl-font-weight-semibold gl-text-gray-900',
          tdClass: 'gl-break-words gl-max-w-0 !gl-text-sm',
        },
        {
          key: 'expected_owner',
          label: s__('DatabaseDiagnostics|Expected Owner'),
          sortable: false,
          thClass: 'gl-w-1/4 gl-min-w-24 !gl-text-sm gl-font-weight-semibold gl-text-gray-900',
          tdClass: 'gl-break-words gl-max-w-0 !gl-text-sm',
        },
      ];
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
    getSequenceOwnershipTableItems(issues) {
      return issues.map((issue) => ({
        sequence_name: issue.name || '',
        current_owner: issue.details?.current_owner || '',
        expected_owner: issue.details?.expected_owner || '',
      }));
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
      <!-- Main Section Header -->
      <div class="gl-flex gl-items-center gl-justify-between gl-rounded-base gl-bg-gray-50 gl-p-3">
        <div class="gl-flex gl-items-center gl-gap-2">
          <gl-icon v-bind="getSectionIcon(section)" class="gl-mr-2" />
          <h4 class="gl-heading-4 gl-mb-0">{{ section.title }}</h4>
          <gl-badge
            v-if="section.issues.length > 0"
            variant="warning"
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
          :icon="expandedSections[section.key] ? 'chevron-up' : 'chevron-down'"
          @click="toggleSection(section.key)"
        >
          {{ s__('DatabaseDiagnostics|Details') }}
        </gl-button>
      </div>

      <!-- Expanded Section Content -->
      <div
        v-if="expandedSections[section.key] && section.issues.length > 0"
        class="gl-mt-2"
        :data-testid="`${section.key}-issues`"
      >
        <!-- Sections with subsections (like sequences) -->
        <div v-if="section.subsections" class="gl-space-y-3">
          <div
            v-for="subsection in section.subsections"
            :key="subsection.key"
            class="gl-rounded-base gl-border-1 gl-border-solid gl-border-orange-200 gl-bg-orange-50"
          >
            <!-- Show subsection only if it has issues -->
            <div v-if="subsection.issues.length > 0" class="gl-p-3">
              <!-- Subsection Header -->
              <h5 class="gl-heading-5 gl-flex gl-items-center gl-gap-2">
                <gl-icon name="warning" :size="16" class="gl-text-orange-500" />
                {{ subsection.title }}
                <gl-badge variant="warning" :data-testid="`${subsection.key}-count`">
                  {{ subsection.issues.length }}
                </gl-badge>
              </h5>

              <!-- Subsection Content -->
              <div class="gl-pl-5">
                <!-- Table format for sequence ownership -->
                <div v-if="subsection.renderType === 'table'" class="gl-overflow-x-auto">
                  <div class="gl-min-w-96">
                    <gl-table
                      :items="getSequenceOwnershipTableItems(subsection.issues)"
                      :fields="sequenceOwnershipTableFields"
                      :small="true"
                      :borderless="true"
                      :data-testid="`${subsection.key}-table`"
                      class="gl-w-full"
                      table-class="gl-table-layout-fixed"
                    />
                  </div>
                </div>

                <!-- List format for other subsections -->
                <div v-else>
                  <div
                    v-for="(issue, index) in subsection.issues"
                    :key="index"
                    class="gl-mb-2 gl-flex gl-items-center gl-text-sm last:gl-mb-0"
                    :data-testid="`${subsection.key}-list-item`"
                  >
                    <gl-icon
                      name="dash"
                      :size="12"
                      class="gl-mr-2 gl-mt-1 gl-flex-shrink-0 gl-text-gray-500"
                    />
                    <span class="gl-flex-grow">
                      {{ issue.name }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Regular sections without subsections -->
        <div
          v-else
          class="gl-rounded-base gl-border-1 gl-border-solid gl-border-orange-200 gl-bg-orange-50 gl-p-3"
        >
          <div class="gl-mb-2">
            <h4
              class="gl-font-weight-semibold gl-mb-0 gl-flex gl-items-center gl-text-base gl-text-gray-900"
            >
              <gl-icon name="warning" :size="16" class="gl-mr-2 gl-text-orange-500" />
              {{ section.issueLabel }}
            </h4>
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
                {{ issue.name }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
