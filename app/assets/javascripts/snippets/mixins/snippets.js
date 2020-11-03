import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';

const blobsDefault = [];

export const getSnippetMixin = {
  apollo: {
    snippet: {
      query: GetSnippetQuery,
      variables() {
        return {
          ids: [this.snippetGid],
        };
      },
      update: data => {
        const res = data.snippets.nodes[0];
        if (res) {
          res.blobs = res.blobs.nodes;
        }

        return res;
      },
      result(res) {
        this.blobs = res.data.snippets.nodes[0]?.blobs || blobsDefault;
      },
      skip() {
        return this.newSnippet;
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
      newSnippet: !this.snippetGid,
      blobs: blobsDefault,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.snippet.loading;
    },
  },
};
