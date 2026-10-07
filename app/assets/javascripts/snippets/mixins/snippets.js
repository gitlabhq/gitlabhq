import { isEmpty } from 'lodash-es';
import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';
import { ERROR_POLICY_NONE } from '~/lib/graphql';
import { logError } from '~/lib/logger';
import { captureException } from '~/sentry/sentry_browser_wrapper';

const blobsDefault = [];

export const getSnippetMixin = {
  apollo: {
    snippet: {
      query: GetSnippetQuery,
      // Skip update() on errored responses; it only handles well-formed data.
      errorPolicy: ERROR_POLICY_NONE,
      variables() {
        return {
          ids: [this.snippetGid],
          ...(this.projectId ? { projectId: this.projectId } : {}),
        };
      },
      update(data) {
        const res = { ...data.snippets.nodes[0] };

        // Set `snippet.blobs` since some child components are coupled to this.
        if (!isEmpty(res)) {
          res.hasUnretrievableBlobs = res.blobs?.hasUnretrievableBlobs || false;
          // It's possible for us to not get any blobs in a response.
          // In this case, we should default to current blobs.
          res.blobs = res.blobs ? res.blobs.nodes : blobsDefault;
          res.description = res.description || '';
        }

        return res;
      },
      skip() {
        return this.newSnippet;
      },
      error(error) {
        this.snippetLoadError = true;
        logError(`Unexpected error while fetching snippet`, error);
        captureException(error, { tags: { vue_component: 'GetSnippetMixin' } });
      },
    },
  },
  props: {
    snippetGid: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      snippet: {},
      newSnippet: !this.snippetGid,
      snippetLoadError: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.snippet.loading;
    },
    blobs() {
      return this.snippet?.blobs || [];
    },
  },
};
