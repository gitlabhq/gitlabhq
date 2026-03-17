<script>
import { GlIcon, GlIntersperse, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';
import BaseToken from './base_token.vue';

export default {
  name: 'WorkItemTypeToken',
  components: {
    BaseToken,
    GlIcon,
    GlIntersperse,
    GlFilteredSearchSuggestion,
    WorkItemTypeIcon,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
      validator: (config) => config.fullPath,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      workItemTypes: this.config.initialWorkItemTypes || [],
    };
  },
  apollo: {
    workItemTypes: {
      query: workItemTypesConfigurationQuery,
      variables() {
        return {
          fullPath: this.config.fullPath,
        };
      },
      update(data) {
        return data?.namespace?.workItemTypes?.nodes || [];
      },
      skip() {
        return !this.config.fullPath;
      },
      error(error) {
        createAlert({
          message: s__(
            'WorkItem|Something went wrong when fetching work item types. Please try again',
          ),
        });
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    filteredWorkItemTypes() {
      return this.workItemTypes.filter(
        (type) =>
          type.isFilterableListView &&
          type.name.toLocaleLowerCase().includes(this.searchTerm.toLocaleLowerCase()),
      );
    },
  },
  methods: {
    fetchSuggestions(searchTerm) {
      this.searchTerm = searchTerm;
    },
    getActiveType(types, data) {
      return types.find((type) => this.getTypeValue(type) === data);
    },
    getTypeValue(type) {
      return type.name.toUpperCase().replace(/\s+/g, '_'); // 'Key Results' -> 'KEY_RESULTS');
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="$apollo.queries.workItemTypes.loading"
    :suggestions="filteredWorkItemTypes"
    :get-active-token-value="getActiveType"
    :value-identifier="getTypeValue"
    v-bind="$attrs"
    @fetch-suggestions="fetchSuggestions"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue, selectedTokens } }">
      <gl-intersperse v-if="selectedTokens.length > 0" separator=", ">
        <span v-for="token in selectedTokens" :key="token">
          {{ workItemTypes.find((type) => getTypeValue(type) === token)?.name || token }}
        </span>
      </gl-intersperse>
      <template v-else>
        {{ activeTokenValue ? activeTokenValue.name : inputValue }}
      </template>
    </template>
    <template #suggestions-list="{ suggestions, selections = [] }">
      <gl-filtered-search-suggestion
        v-for="type in suggestions"
        :key="getTypeValue(type)"
        :value="getTypeValue(type)"
      >
        <div
          class="gl-flex gl-items-center"
          :class="{ 'gl-pl-6': !selections.includes(getTypeValue(type)) }"
        >
          <gl-icon
            v-if="selections.includes(getTypeValue(type))"
            name="check"
            class="gl-mr-3 gl-shrink-0"
            variant="subtle"
          />
          <work-item-type-icon
            :work-item-type="type.name"
            :type-icon-name="type.iconName"
            show-text
            class="gl-whitespace-nowrap"
          />
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
