<script>
import { historyPushState, historyReplaceState } from '~/lib/utils/common_utils';
import { mergeUrlParams, setUrlParams } from '~/lib/utils/url_utility';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export const HISTORY_PUSH_UPDATE_METHOD = 'push';
export const HISTORY_REPLACE_UPDATE_METHOD = 'replace';
export const URL_SET_PARAMS_STRATEGY = 'set';
export const URL_MERGE_PARAMS_STRATEGY = 'merge';

/**
 * Renderless component to update the query string,
 * the update is done by updating the query property or
 * by using updateQuery method in the scoped slot.
 * note: do not use both prop and updateQuery method.
 *
 * When a `router` prop is provided (Vue Router instance), query updates
 * will use router.push/replace instead of direct history manipulation.
 * This ensures compatibility with Vue Router's navigation system.
 */
export default normalizeRender({
  props: {
    query: {
      type: Object,
      required: false,
      default: null,
    },
    urlParamsUpdateStrategy: {
      type: String,
      required: false,
      default: URL_MERGE_PARAMS_STRATEGY,
      validator: (value) => [URL_MERGE_PARAMS_STRATEGY, URL_SET_PARAMS_STRATEGY].includes(value),
    },
    historyUpdateMethod: {
      type: String,
      required: false,
      default: HISTORY_PUSH_UPDATE_METHOD,
      validator: (value) =>
        [HISTORY_PUSH_UPDATE_METHOD, HISTORY_REPLACE_UPDATE_METHOD].includes(value),
    },
    useRouter: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    query: {
      immediate: true,
      deep: true,
      handler(newQuery) {
        if (newQuery) {
          this.updateQuery(newQuery);
        }
      },
    },
    '$route.query': {
      deep: true,
      handler(newQuery, oldQuery) {
        if (this.useRouter && JSON.stringify(newQuery) !== JSON.stringify(oldQuery)) {
          this.$emit('popstate', { state: { query: newQuery } });
        }
      },
    },
  },
  mounted() {
    if (!this.useRouter) {
      window.addEventListener('popstate', this.handlePopState);
    }
  },
  beforeDestroy() {
    if (!this.useRouter) {
      window.removeEventListener('popstate', this.handlePopState);
    }
  },
  methods: {
    handlePopState(event) {
      this.$emit('popstate', event);
    },
    updateQuery(newQuery) {
      if (this.useRouter) {
        this.updateQueryViaRouter(newQuery);
      } else {
        this.updateQueryViaHistory(newQuery);
      }
    },
    updateQueryViaRouter(newQuery) {
      const currentQuery = this.$route?.query || {};
      let mergedQuery;

      if (this.urlParamsUpdateStrategy === URL_SET_PARAMS_STRATEGY) {
        mergedQuery = { ...newQuery };
      } else {
        const normalizedCurrentQuery = {};
        Object.keys(currentQuery).forEach((key) => {
          const normalizedKey = key.replace(/\[\]$/, '');
          normalizedCurrentQuery[normalizedKey] = currentQuery[key];
        });
        mergedQuery = { ...normalizedCurrentQuery, ...newQuery };
      }

      const finalQuery = {};
      Object.keys(mergedQuery).forEach((key) => {
        const value = mergedQuery[key];
        if (value === null || value === undefined) {
          return;
        }
        if (Array.isArray(value)) {
          finalQuery[`${key}[]`] = value;
        } else {
          finalQuery[key] = value;
        }
      });

      if (JSON.stringify(currentQuery) === JSON.stringify(finalQuery)) {
        return;
      }

      const navigationMethod =
        this.historyUpdateMethod === HISTORY_PUSH_UPDATE_METHOD ? 'push' : 'replace';

      this.$router[navigationMethod]({ query: finalQuery }).catch((err) => {
        if (err.name !== 'NavigationDuplicated') {
          throw err;
        }
      });
    },
    updateQueryViaHistory(newQuery) {
      const url =
        this.urlParamsUpdateStrategy === URL_SET_PARAMS_STRATEGY
          ? setUrlParams(this.query, {
              url: window.location.href,
              clearParams: true,
              railsArraySyntax: true,
              decodeParams: true,
            })
          : mergeUrlParams(newQuery, window.location.href, { spreadArrays: true });

      if (this.historyUpdateMethod === HISTORY_PUSH_UPDATE_METHOD) {
        historyPushState(url);
      } else {
        historyReplaceState(url);
      }
    },
  },
  render() {
    return this.$scopedSlots.default?.({ updateQuery: this.updateQuery });
  },
});
</script>
