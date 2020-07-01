import GetSnippetQuery from '../queries/snippet.query.graphql';

export const getSnippetMixin = {
  apollo: {
    snippet: {
      query: GetSnippetQuery,
      variables() {
        return {
          ids: this.snippetGid,
        };
      },
      update: data => data.snippets.edges[0]?.node,
      result(res) {
        this.blobs = res.data.snippets.edges[0].node.blobs;
        if (this.onSnippetFetch) {
          this.onSnippetFetch(res);
        }
      },
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
      newSnippet: false,
      blobs: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.snippet.loading;
    },
  },
};

export default () => {};
