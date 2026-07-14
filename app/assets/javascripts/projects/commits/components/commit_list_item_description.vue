<script>
import { createAlert } from '~/alert';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import commitDescriptionQuery from '../graphql/queries/commit_details.query.graphql';

const NEWLINE_CHAR = '&#x000A;';

export default {
  name: 'CommitListItemDescription',
  directives: { SafeHtml },
  inject: ['projectFullPath'],
  props: {
    commitSha: {
      type: String,
      required: true,
    },
  },
  emits: ['loaded'],
  data() {
    return { descriptionHtml: null };
  },
  apollo: {
    descriptionHtml: {
      query: commitDescriptionQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.commitSha,
        };
      },
      // Let the parent gate its open animation until the description is ready.
      result() {
        this.$emit('loaded');
      },
      update(data) {
        let { descriptionHtml } = data.project?.repository?.commit || {};

        if (descriptionHtml?.startsWith(NEWLINE_CHAR)) {
          // Remove newline to avoid extra empty line before the description
          // See: https://gitlab.com/gitlab-org/gitlab/-/issues/515892#note_2380061342
          descriptionHtml = descriptionHtml.substring(NEWLINE_CHAR.length);
        }

        return descriptionHtml;
      },
      error(error) {
        // Still signal the parent so the row can open even when loading failed.
        this.$emit('loaded');
        createAlert({
          message:
            error.message ||
            s__(
              'Commits|Something went wrong while loading the commit description. Please try again.',
            ),
          captureError: true,
          error,
        });
      },
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>

<template>
  <pre
    v-if="descriptionHtml"
    v-safe-html:[$options.safeHtmlConfig]="descriptionHtml"
    class="gl-mb-0 gl-border-none"
  ></pre>
</template>
