<script>
import { GlAlert, GlButton, GlPagination, GlSprintf } from '@gitlab/ui';
import { historyImportOfflineExportPath } from '~/lib/utils/path_helpers/import';
import { n__ } from '~/locale';
import GroupRow from '~/import/offline_transfer/components/group_row.vue';

export default {
  name: 'ReviewExportTab',
  components: {
    GroupRow,
    GlAlert,
    GlButton,
    GlPagination,
    GlSprintf,
  },
  props: {
    selectedGroups: {
      type: Array,
      required: true,
    },
    bucketName: {
      type: String,
      required: true,
    },
    hasSubmitSucceeded: {
      type: Boolean,
      required: false,
      default: false,
    },
    submissionError: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      currentPage: 1,
    };
  },
  computed: {
    reviewText() {
      return n__(
        'OfflineTransferExport|%{count} group will be exported to %{bucket}. Select %{boldStart}Start export%{boldEnd} to confirm.',
        'OfflineTransferExport|%{count} groups will be exported to %{bucket}. Select %{boldStart}Start export%{boldEnd} to confirm.',
        this.groupCount,
      );
    },
    groupCount() {
      return this.selectedGroups.length;
    },
    successText() {
      return n__(
        "OfflineTransferExport|You can leave this page. We'll email you when the export of the group is finished and the package is ready in bucket %{bucket}.",
        "OfflineTransferExport|You can leave this page. We'll email you when the export of %{count} groups is finished and the package is ready in bucket %{bucket}.",
        this.groupCount,
      );
    },
    pageGroups() {
      const start = (this.currentPage - 1) * this.$options.PAGE_SIZE;
      return this.selectedGroups.slice(start, start + this.$options.PAGE_SIZE);
    },
    showPagination() {
      return this.selectedGroups.length > this.$options.PAGE_SIZE;
    },
    offlineExportHistoryPath() {
      return historyImportOfflineExportPath();
    },
  },
  watch: {
    selectedGroups() {
      this.currentPage = 1;
    },
  },
  PAGE_SIZE: 10,
};
</script>

<template>
  <div v-if="hasSubmitSucceeded" data-testid="submit-success">
    <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Export started') }}</h2>
    <p class="gl-max-w-2xl">
      <gl-sprintf :message="successText">
        <template #count>{{ groupCount }}</template>
        <template #bucket
          ><strong>{{ bucketName }}</strong></template
        >
      </gl-sprintf>
    </p>
    <gl-button
      :href="offlineExportHistoryPath"
      variant="confirm"
      data-testid="view-export-status-button"
    >
      {{ s__('OfflineTransferExport|View export status') }}
    </gl-button>
  </div>
  <div v-else>
    <gl-alert
      v-if="submissionError"
      :title="s__('OfflineTransferExport|Export failed')"
      variant="danger"
      :dismissible="false"
      class="gl-mb-5"
      data-testid="submit-error"
    >
      {{ submissionError }}
    </gl-alert>
    <p v-if="!submissionError" class="gl-leading-24" data-testid="review-text">
      <gl-sprintf :message="reviewText">
        <template #count>{{ groupCount }}</template>
        <template #bucket
          ><strong>{{ bucketName }}</strong></template
        >
        <template #bold="{ content }"
          ><strong>{{ content }}</strong></template
        >
      </gl-sprintf>
    </p>
    <ul class="gl-mb-0 gl-list-none gl-p-0">
      <group-row
        v-for="group in pageGroups"
        :key="group.id"
        :name="group.fullName"
        :description="group.description"
        :avatar-url="group.avatarUrl"
      />
    </ul>
    <gl-pagination
      v-if="showPagination"
      v-model="currentPage"
      :per-page="$options.PAGE_SIZE"
      :total-items="groupCount"
      align="center"
    />
  </div>
</template>
