<script>
import { GlLoadingIcon, GlKeysetPagination, GlPagination } from '@gitlab/ui';
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
  PAGINATION_TYPE_KEYSET,
  PAGINATION_TYPE_OFFSET,
} from '../constants';

const trackingMixin = InternalEvents.mixin();

export default {
  PAGINATION_TYPE_KEYSET,
  PAGINATION_TYPE_OFFSET,
  name: 'TabView',
  i18n: {
    errorMessage: __(
      'An error occurred loading the projects. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    GlPagination,
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
    page: {
      type: Number,
      required: false,
      default: 1,
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
    paginationType: {
      type: String,
      required: true,
      validator(value) {
        return [PAGINATION_TYPE_KEYSET, PAGINATION_TYPE_OFFSET].includes(value);
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
            ...(this.paginationType === PAGINATION_TYPE_KEYSET ? this.keysetPagination : {}),
            ...(this.paginationType === PAGINATION_TYPE_OFFSET ? this.offsetPagination : {}),
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
          const { nodes, pageInfo, count } = get(response, this.tab.queryPath);

          return {
            nodes: this.tab.formatter(nodes),
            pageInfo,
            count,
          };
        },
        result() {
          this.$emit('query-complete');
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
    keysetPagination() {
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
    offsetPagination() {
      return { page: this.page };
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
  watch: {
    'items.count': function watchCount(newCount) {
      this.$emit('update-count', this.tab, newCount);
    },
  },
  methods: {
    async onRefetch() {
      await this.apolloClient.clearStore();
      this.$apollo.queries.items.refetch();
      this.$emit('refetch');
    },
    onKeysetNext(endCursor) {
      this.$emit('keyset-page-change', {
        endCursor,
        startCursor: null,
      });
    },
    onKeysetPrev(startCursor) {
      this.$emit('keyset-page-change', {
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
    onClickTopic() {
      if (!this.eventTracking?.clickTopic) {
        return;
      }

      this.trackEvent(this.eventTracking.clickTopic);
    },
    onOffsetInput(page) {
      this.$emit('offset-page-change', page);
    },
    onClickAvatar() {
      if (!this.eventTracking?.clickItemAfterFilter) {
        return;
      }

      const activeFilters = Object.entries(this.filters).reduce((accumulator, [key, value]) => {
        // Exclude filters that have no value.
        if (!value) {
          return accumulator;
        }

        if (key === this.filteredSearchTermKey) {
          // For privacy reasons, don't keep track of user provided values
          // eslint-disable-next-line @gitlab/require-i18n-strings
          return { ...accumulator, search: 'user provided value' };
        }

        return { ...accumulator, [key]: value };
      }, {});

      if (!Object.keys(activeFilters).length) {
        return;
      }

      this.trackEvent(this.eventTracking.clickItemAfterFilter, {
        label: this.tab.value,
        property: JSON.stringify(activeFilters),
      });
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
      @click-avatar="onClickAvatar"
      @click-topic="onClickTopic"
    />
    <template v-if="paginationType === $options.PAGINATION_TYPE_OFFSET">
      <div v-if="pageInfo.nextPage || pageInfo.previousPage" class="gl-mt-5">
        <gl-pagination
          :value="page"
          :per-page="pageInfo.perPage"
          :total-items="pageInfo.total"
          align="center"
          @input="onOffsetInput"
        />
      </div>
    </template>
    <template v-else-if="paginationType === $options.PAGINATION_TYPE_KEYSET">
      <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
        <gl-keyset-pagination v-bind="pageInfo" @prev="onKeysetPrev" @next="onKeysetNext" />
      </div>
    </template>
  </div>
  <component :is="tab.emptyStateComponent" v-else v-bind="emptyStateComponentProps" />
</template>
