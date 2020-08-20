import GetSnippetQuery from '../queries/snippet.query.graphql';

const blobsDefault = [];

// eslint-disable-next-line import/prefer-default-export
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
        this.blobs = res.data.snippets.edges[0]?.node?.blobs || blobsDefault;
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
      blobs: blobsDefault,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.snippet.loading;
    },
  },
};
