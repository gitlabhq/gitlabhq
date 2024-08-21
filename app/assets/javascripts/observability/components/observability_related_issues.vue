<script>
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import { TYPE_ISSUE } from '~/issues/constants';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { ISSUE_PATH_ID_SEPARATOR } from '../constants';

export default {
  components: {
    RelatedIssuesBlock,
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
    fetchingIssues: {
      type: Boolean,
      required: true,
    },
    error: {
      type: Error,
      required: false,
      default: null,
    },
    helpPath: {
      type: String,
      required: true,
    },
  },
  watch: {
    error: {
      handler(e) {
        if (e) {
          // Wait for this component to render
          this.$nextTick(() => {
            createAlert({
              error: e,
              message: s__('Observability|Failed to load related issues. Try reloading the page.'),
              parent: this.$el,
              captureError: true,
            });
          });
        }
      },
      immediate: true,
    },
  },
  TYPE_ISSUE,
  ISSUE_PATH_ID_SEPARATOR,
};
</script>

<template>
  <section>
    <div data-testid="alert-container" class="flash-container"></div>
    <related-issues-block
      :header-text="s__('Observability|Related issues')"
      :help-path="helpPath"
      :is-fetching="fetchingIssues"
      :related-issues="issues"
      :can-admin="false"
      :can-reorder="false"
      :is-form-visible="false"
      :show-categorized-issues="false"
      :issuable-type="$options.TYPE_ISSUE"
      :path-id-separator="$options.ISSUE_PATH_ID_SEPARATOR"
    >
      <template #empty-state-message>
        {{ s__('Observability|Create issues from this page to view them as related items here.') }}
      </template>
    </related-issues-block>
  </section>
</template>
