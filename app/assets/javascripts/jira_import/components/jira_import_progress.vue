<script>
import { GlEmptyState } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';

export default {
  name: 'JiraImportProgress',
  components: {
    GlEmptyState,
  },
  props: {
    illustration: {
      type: String,
      required: true,
    },
    importInitiator: {
      type: String,
      required: true,
    },
    importProject: {
      type: String,
      required: true,
    },
    importTime: {
      type: String,
      required: true,
    },
    issuesPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    importInitiatorText() {
      return sprintf(__('Import started by: %{importInitiator}'), {
        importInitiator: this.importInitiator,
      });
    },
    importProjectText() {
      return sprintf(__('Jira project: %{importProject}'), {
        importProject: this.importProject,
      });
    },
    importTimeText() {
      return sprintf(__('Time of import: %{importTime}'), {
        importTime: formatDate(this.importTime),
      });
    },
    issuesLink() {
      return `${this.issuesPath}?search=${this.importProject}`;
    },
  },
};
</script>

<template>
  <gl-empty-state
    :svg-path="illustration"
    :title="__('Import in progress')"
    :primary-button-text="__('View issues')"
    :primary-button-link="issuesLink"
  >
    <template #description>
      <p class="mb-0">{{ importInitiatorText }}</p>
      <p class="mb-0">{{ importTimeText }}</p>
      <p class="mb-0">{{ importProjectText }}</p>
    </template>
  </gl-empty-state>
</template>
