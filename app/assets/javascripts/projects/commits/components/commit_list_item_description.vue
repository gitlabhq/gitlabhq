<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import commitDescriptionQuery from '../graphql/queries/commit_details.query.graphql';

const NEWLINE_CHAR = '&#x000A;';

export default {
  name: 'CommitListItemDescription',
  directives: { SafeHtml },
  components: {
    GlLoadingIcon,
  },
  inject: ['projectFullPath'],
  props: {
    commitSha: {
      type: String,
      required: true,
    },
  },
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
  computed: {
    isLoading() {
      return this.$apollo.queries.descriptionHtml.loading;
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" />

  <pre
    v-else-if="descriptionHtml"
    v-safe-html:[$options.safeHtmlConfig]="descriptionHtml"
    class="gl-mb-0 gl-border-none"
  ></pre>
</template>
