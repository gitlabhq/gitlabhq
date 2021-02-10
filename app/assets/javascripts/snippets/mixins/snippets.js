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
      update(data) {
        const res = data.snippets.nodes[0];

        // Set `snippet.blobs` since some child components are coupled to this.
        if (res) {
          // It's possible for us to not get any blobs in a response.
          // In this case, we should default to current blobs.
          res.blobs = res.blobs ? res.blobs.nodes : this.blobs;
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
