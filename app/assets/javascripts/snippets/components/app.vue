<script>
import getSnippet from '../queries/getSnippet.query.graphql';

export default {
  apollo: {
    snippetData: {
      query: getSnippet,
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
      snippetData: {},
    };
  },
};
</script>
<template>
  <div class="js-snippet-view"></div>
</template>
