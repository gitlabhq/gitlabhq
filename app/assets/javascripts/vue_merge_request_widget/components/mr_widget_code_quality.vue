<script>
import issuesBlock from './mr_widget_code_quality_issues.vue';

export default {
  name: 'MRWidgetCodeQuality',
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    loadingFailed: {
      type: Boolean,
      required: true,
    },
    newIssues: {
      type: Array,
      required: false,
      default: () => ([]),
    },
    resolvedIssues: {
      type: Array,
      required: false,
      default: () => ([]),
    },
  },
  components: {
    issuesBlock,
  },
  computed: {
    shouldShowLoading() {
      return this.isLoading && !this.loadingFailed;
    },
    shouldShowCodeQuality() {
      return !this.isLoading && !this.loadingFailed;
    },
    shouldShowLoadFailure() {
      return !this.isLoading && this.loadingFailed;
    },
  },
};
</script>
<template>
  <section class="mr-widget-code-quality well">
    <p
      v-if="shouldShowLoading"
      class="usage-info js-usage-info usage-info-loading">
      <i
        class="fa fa-spinner fa-spin usage-info-load-spinner"
        aria-hidden="true" />Loading codeclimate report.
    </p>
    <div v-else-if="shouldShowCodeQuality">
      <issues-block
        class="js-mr-code-new-issues"
        v-if="newIssues.length"
        title="Issues introduced in this merge request:"
        :issues="newIssues"
        />

      <issues-block
        class="js-mr-code-resolved-issues"
        v-if="resolvedIssues.length"
        title="Issues resolved in this merge request:"
        :issues="resolvedIssues"
        />
    </div>
    <p
      v-else-if="shouldShowLoadFailure">
      Failed to load codeclimate report.
    </p>
  </section>
</template>
