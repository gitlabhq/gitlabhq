<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  WORK_ITEM_TYPE_ENUM_EPIC,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_ISSUE,
} from '~/work_items/constants';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import searchWorkItemParentQuery from '../queries/search_work_item_parent.query.graphql';
import { OPTIONS_NONE_ANY } from '../constants';

export default {
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
      workItems: this.config.initialWorkItems || [],
      loading: false,
    };
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
    supportedTypes() {
      // TODO: Populate this list dynamically
      // https://gitlab.com/gitlab-org/gitlab/-/issues/560430
      return this.config.isProject
        ? [WORK_ITEM_TYPE_ENUM_EPIC, WORK_ITEM_TYPE_ENUM_OBJECTIVE, WORK_ITEM_TYPE_ENUM_ISSUE]
        : [WORK_ITEM_TYPE_ENUM_EPIC];
    },
  },
  methods: {
    async fetchWorkItemsBySearchTerm(search = '') {
      this.loading = true;

      try {
        const { data } = await this.$apollo.query({
          query: searchWorkItemParentQuery,
          variables: {
            fullPath: this.config.fullPath,
            groupPath: this.groupPath,
            search,
            in: search ? 'TITLE' : undefined,
            includeDescendants: !this.config.isProject,
            includeAncestors: true,
            types: this.supportedTypes,
            isProject: this.config.isProject,
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
        return workItems.find((workItem) => this.getValue(workItem) === data);
      }
      return undefined;
    },
    getValue(workItem) {
      return getIdFromGraphQLId(workItem[this.idProperty]).toString();
    },
    displayValue(workItem) {
      return workItem?.title;
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
      {{ activeTokenValue ? displayValue(activeTokenValue) : inputValue }}
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
