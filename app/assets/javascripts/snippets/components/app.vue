<script>
import GetSnippetQuery from '../queries/snippet.query.graphql';
import SnippetHeader from './snippet_header.vue';
import SnippetTitle from './snippet_title.vue';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    SnippetHeader,
    SnippetTitle,
    GlLoadingIcon,
  },
  apollo: {
    snippet: {
      query: GetSnippetQuery,
      variables() {
        return {
          ids: this.snippetGid,
        };
      },
      update: data => data.snippets.edges[0].node,
    },
  },
  props: {
    snippetGid: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      snippet: {},
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.snippet.loading;
    },
  },
};
</script>
<template>
  <div class="js-snippet-view">
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      :size="2"
      class="loading-animation prepend-top-20 append-bottom-20"
    />
    <template v-else>
      <snippet-header :snippet="snippet" />
      <snippet-title :snippet="snippet" />
    </template>
  </div>
</template>
