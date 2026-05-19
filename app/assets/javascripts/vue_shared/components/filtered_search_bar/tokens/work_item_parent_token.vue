<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { unionBy } from 'lodash-es';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import { WIDGET_TYPE_HIERARCHY } from '~/work_items/constants';
import allowedParentTypesQuery from '~/work_items/graphql/allowed_parent_types.query.graphql';
import searchWorkItemParentQuery from '../queries/search_work_item_parent.query.graphql';
import { OPTIONS_NONE_ANY } from '../constants';

export default {
  name: 'WorkItemParentToken',
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      allowedParentTypes: [],
      workItems: this.config.initialWorkItems || [],
      loading: false,
    };
  },
  apollo: {
    allowedParentTypes: {
      query: allowedParentTypesQuery,
      variables() {
        return {
          fullPath: this.config.fullPath,
        };
      },
      update(data) {
        const allowedParentTypes = data.namespace.workItemTypes.nodes
          .flatMap(
            (type) =>
              type.widgetDefinitions.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)
                ?.allowedParentTypes.nodes,
          )
          .filter((type) => Boolean(type));
        return unionBy(allowedParentTypes, 'id');
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    idProperty() {
      return this.config.idProperty || 'iid';
    },
    defaultWorkItems() {
      return this.config.defaultWorkItems || OPTIONS_NONE_ANY;
    },
    groupPath() {
      return this.config.isProject
        ? this.config.fullPath.substring(0, this.config.fullPath.lastIndexOf('/'))
        : this.config.fullPath;
    },
  },
  methods: {
    async fetchWorkItemsBySearchTerm(search = '') {
      this.loading = true;
      const isSearchedById = /^\d+$/.test(search);
      const refinedSearchText = isSearchedById ? '' : search;

      try {
        // The logic to fetch the Parent seems to be different than other pages
        // Below issue targets to have a common logic across work items app
        // https://gitlab.com/gitlab-org/gitlab/-/issues/571302
        const { data } = await this.$apollo.query({
          query: searchWorkItemParentQuery,
          variables: {
            fullPath: this.config.fullPath,
            groupPath: this.groupPath,
            search: refinedSearchText,
            in: refinedSearchText ? 'TITLE' : undefined,
            includeDescendants: !this.config.isProject,
            includeAncestors: true,
            workItemTypeIds: this.allowedParentTypes.map((type) => type.id),
            isProject: this.config.isProject,
            ids: isSearchedById ? [convertToGraphQLId(TYPENAME_WORK_ITEM, search)] : undefined,
          },
        });

        const groupWorkItems = data.group?.workItems?.nodes || [];
        const projectWorkItems = data.project?.workItems?.nodes || [];

        this.workItems = [...groupWorkItems, ...projectWorkItems];
      } catch (error) {
        createAlert({ message: __('There was a problem fetching the parent items.') });
      } finally {
        this.loading = false;
      }
    },
    getActiveWorkItem(workItems, data) {
      if (data && workItems.length) {
        return workItems.find((workItem) => this.getValue(workItem) === data?.toString());
      }
      return undefined;
    },
    getValue(workItem) {
      return getIdFromGraphQLId(workItem[this.idProperty]).toString();
    },
    displayValue(workItem, inputValue) {
      if (workItem?.title) {
        return workItem?.title;
      }

      return (
        this.workItems.find((item) => {
          return this.getValue(item) === inputValue?.toString();
        })?.title || inputValue
      );
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="workItems"
    :get-active-token-value="getActiveWorkItem"
    :default-suggestions="defaultWorkItems"
    search-by="title"
    :value-identifier="getValue"
    v-bind="$attrs"
    @fetch-suggestions="fetchWorkItemsBySearchTerm"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ displayValue(activeTokenValue, inputValue) }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="workItem in suggestions"
        :key="workItem.id"
        :value="getValue(workItem)"
      >
        {{ workItem.title }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
