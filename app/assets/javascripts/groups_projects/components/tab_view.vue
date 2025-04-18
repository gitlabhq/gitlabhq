<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import { get } from 'lodash';
import { DEFAULT_PER_PAGE } from '~/api';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { TIMESTAMP_TYPES } from '~/vue_shared/components/resource_lists/constants';
import { ACCESS_LEVELS_INTEGER_TO_STRING } from '~/access_level/constants';
import { COMPONENT_NAME as NESTED_GROUPS_PROJECTS_LIST_COMPONENT_NAME } from '~/vue_shared/components/nested_groups_projects_list/constants';
import { InternalEvents } from '~/tracking';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '../constants';

const trackingMixin = InternalEvents.mixin();

// Will be made more generic to work with groups and projects in future commits
export default {
  name: 'TabView',
  i18n: {
    errorMessage: __(
      'An error occurred loading the projects. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
  },
  mixins: [trackingMixin],
  props: {
    tab: {
      required: true,
      type: Object,
    },
    startCursor: {
      type: String,
      required: false,
      default: null,
    },
    endCursor: {
      type: String,
      required: false,
      default: null,
    },
    sort: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: true,
    },
    filteredSearchTermKey: {
      type: String,
      required: true,
    },
    timestampType: {
      type: String,
      required: false,
      default: undefined,
      validator(value) {
        return TIMESTAMP_TYPES.includes(value);
      },
    },
    programmingLanguages: {
      type: Array,
      required: true,
    },
    eventTracking: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  data() {
    return {
      items: {},
    };
  },
  apollo: {
    items() {
      return {
        query: this.tab.query,
        variables() {
          const { transformVariables } = this.tab;

          const variables = {
            ...this.pagination,
            ...this.tab.variables,
            sort: this.sort,
            programmingLanguageName: this.programmingLanguageName,
            minAccessLevel: this.minAccessLevel,
            search: this.search,
          };
          const transformedVariables = transformVariables
            ? transformVariables(variables)
            : variables;

          return transformedVariables;
        },
        update(response) {
          const { nodes, pageInfo } = get(response, this.tab.queryPath);

          return {
            nodes: this.tab.formatter(nodes),
            pageInfo,
          };
        },
        error(error) {
          createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
        },
      };
    },
  },
  computed: {
    nodes() {
      return this.items.nodes || [];
    },
    pageInfo() {
      return this.items.pageInfo || {};
    },
    pagination() {
      if (!this.startCursor && !this.endCursor) {
        return {
          first: DEFAULT_PER_PAGE,
          after: null,
          last: null,
          before: null,
        };
      }

      return {
        first: this.endCursor && DEFAULT_PER_PAGE,
        after: this.endCursor,
        last: this.startCursor && DEFAULT_PER_PAGE,
        before: this.startCursor,
      };
    },
    isLoading() {
      return this.$apollo.queries.items.loading;
    },
    search() {
      return this.filters[this.filteredSearchTermKey];
    },
    minAccessLevel() {
      const { [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: minAccessLevelInteger } = this.filters;

      return minAccessLevelInteger && ACCESS_LEVELS_INTEGER_TO_STRING[minAccessLevelInteger];
    },
    programmingLanguageName() {
      const { [FILTERED_SEARCH_TOKEN_LANGUAGE]: programmingLanguageId } = this.filters;

      return (
        programmingLanguageId &&
        this.programmingLanguages.find(({ id }) => id === parseInt(programmingLanguageId, 10))?.name
      );
    },
    apolloClient() {
      return this.$apollo.provider.defaultClient;
    },
    emptyStateComponentProps() {
      return {
        search: this.search,
        ...this.tab.emptyStateComponentProps,
      };
    },
    listComponentProps() {
      const baseProps = {
        items: this.nodes,
        timestampType: this.timestampType,
        ...this.tab.listComponentProps,
      };

      if (this.tab.listComponent.name === NESTED_GROUPS_PROJECTS_LIST_COMPONENT_NAME) {
        return {
          ...baseProps,
          initialExpanded: Boolean(this.search),
        };
      }

      return baseProps;
    },
  },
  methods: {
    onRefetch() {
      this.apolloClient.resetStore();
      this.$apollo.queries.items.refetch();
    },
    onNext(endCursor) {
      this.$emit('page-change', {
        endCursor,
        startCursor: null,
      });
    },
    onPrev(startCursor) {
      this.$emit('page-change', {
        endCursor: null,
        startCursor,
      });
    },
    findItemById(items, id) {
      if (!items?.length) {
        return null;
      }

      for (let i = 0; i < items.length; i += 1) {
        const item = items[i];

        // Check if current item has the ID we're looking for
        if (item.id === id) {
          return item;
        }

        // If item has children, recursively search its children
        if (item.children?.length) {
          const childItem = this.findItemById(item.children, id);

          if (childItem !== null) {
            return childItem;
          }
        }
      }

      // Item not found at any level
      return null;
    },
    async onLoadChildren(parentId) {
      const item = this.findItemById(this.nodes, parentId);

      if (!item) {
        return;
      }

      item.childrenLoading = true;

      try {
        const response = await this.$apollo.query({
          query: this.tab.query,
          variables: { parentId },
        });
        const { nodes } = get(response.data, this.tab.queryPath);

        item.children = this.tab.formatter(nodes);
      } catch (error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      } finally {
        item.childrenLoading = false;
      }
    },
    onHoverVisibility(visibility) {
      if (!this.eventTracking?.hoverVisibility) {
        return;
      }

      this.trackEvent(this.eventTracking.hoverVisibility, { label: visibility });
    },
    onHoverStat(stat) {
      if (!this.eventTracking?.hoverStat) {
        return;
      }

      this.trackEvent(this.eventTracking.hoverStat, { label: stat });
    },
    onClickStat(stat) {
      if (!this.eventTracking?.clickStat) {
        return;
      }

      this.trackEvent(this.eventTracking.clickStat, { label: stat });
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <div v-else-if="nodes.length">
    <component
      :is="tab.listComponent"
      v-bind="listComponentProps"
      @refetch="onRefetch"
      @load-children="onLoadChildren"
      @hover-visibility="onHoverVisibility"
      @hover-stat="onHoverStat"
      @click-stat="onClickStat"
    />
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </div>
  <component :is="tab.emptyStateComponent" v-else v-bind="emptyStateComponentProps" />
</template>
