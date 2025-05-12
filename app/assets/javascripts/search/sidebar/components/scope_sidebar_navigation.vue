<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState, mapMutations } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import getBlobSearchCountQuery from '~/search/graphql/blob_search_zoekt_count_only.query.graphql';
import { DEFAULT_FETCH_CHUNKS } from '~/search/results/constants';
import { RECEIVE_NAVIGATION_COUNT } from '../../store/mutation_types';
import { NAV_LINK_DEFAULT_CLASSES, NAV_LINK_COUNT_DEFAULT_CLASSES, SCOPE_BLOB } from '../constants';

export default {
  name: 'ScopeSidebarNavigation',
  i18n: {
    countOverLimitLabel: s__('GlobalSearch|Result count is over limit.'),
  },
  components: {
    NavItem,
    MenuSection,
  },
  apollo: {
    blobSearchCount: {
      query: getBlobSearchCountQuery,
      variables() {
        return {
          search: this.query.search,
          groupId: this.query?.group_id && convertToGraphQLId(TYPENAME_GROUP, this.query.group_id),
          chunkCount: DEFAULT_FETCH_CHUNKS,
          projectId:
            this.query?.project_id && convertToGraphQLId(TYPENAME_PROJECT, this.query.project_id),
          regex: parseBoolean(this.query?.regex),
          includeArchived: parseBoolean(this.query.include_archived),
          includeForked: parseBoolean(this.query.include_forked),
        };
      },
      skip() {
        return this.legacyBlobsCount;
      },
      update(data) {
        this.receiveNavigationCount({
          key: SCOPE_BLOB,
          count: data?.blobSearch?.matchCount.toString(),
        });
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      showFlyoutMenus: false,
      blobSearchCount: null,
    };
  },
  computed: {
    ...mapGetters(['navigationItems', 'currentScope']),
    ...mapState(['zoektAvailable', 'query']),
    legacyBlobsCount() {
      if (this.currentScope === SCOPE_BLOB) {
        // if current scope is blobs skip this no matter what
        return true;
      }

      if (!this.zoektAvailable) {
        // skip this if no multimatch feature is available
        return true;
      }

      if (
        !this.glFeatures.zoektCrossNamespaceSearch &&
        !(this.query?.group_id || this.query?.project_id)
      ) {
        // skip this if we have no group or project ID or crossNamespaceSearch is enabled
        return true;
      }

      return false;
    },
  },
  created() {
    this.fetchSidebarCount(this.legacyBlobsCount);
  },
  methods: {
    ...mapActions(['fetchSidebarCount']),
    ...mapMutations({ receiveNavigationCount: RECEIVE_NAVIGATION_COUNT }),
    showWorkItems(subitems = []) {
      return this.glFeatures.workItemScopeFrontend && subitems.length > 0;
    },
  },
  NAV_LINK_DEFAULT_CLASSES,
  NAV_LINK_COUNT_DEFAULT_CLASSES,
};
</script>

<template>
  <nav data-testid="search-filter" class="gl-relative gl-py-2">
    <ul class="gl-list-none gl-px-2">
      <template v-for="item in navigationItems">
        <menu-section
          v-if="showWorkItems(item.items)"
          :key="item.id"
          :item="item"
          :separated="item.separated"
          :has-flyout="showFlyoutMenus"
          :expanded="true"
          tag="li"
        />
        <nav-item v-else :key="`navItem-${item.id}`" :item="item" />
      </template>
    </ul>
  </nav>
</template>
