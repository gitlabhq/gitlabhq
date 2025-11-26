<script>
import { GlIcon, GlIntersperse, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { getTypeTokenOptions } from 'ee_else_ce/issues/list/utils';
import BaseToken from './base_token.vue';

export default {
  name: 'WorkItemTypeToken',
  components: {
    BaseToken,
    GlIcon,
    GlIntersperse,
    GlFilteredSearchSuggestion,
  },
  inject: [
    'hasEpicsFeature',
    'hasOkrsFeature',
    'hasQualityManagementFeature',
    'isGroupIssuesList',
    'isProject',
  ],
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
  computed: {
    workItemTypes() {
      return getTypeTokenOptions({
        hasEpicsFeature: this.hasEpicsFeature,
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
        isGroupIssuesList: this.isGroupIssuesList,
        isProject: this.isProject,
      });
    },
  },
  methods: {
    getActiveType(types, data) {
      return types.find((type) => type.value === data);
    },
    getTypeValue(type) {
      return type.value;
    },
    getTypeTitle(type) {
      return type.title;
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions="workItemTypes"
    :get-active-token-value="getActiveType"
    :value-identifier="getTypeValue"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue, selectedTokens } }">
      <gl-intersperse v-if="selectedTokens.length > 0" separator=", ">
        <span v-for="token in selectedTokens" :key="token">
          {{ getTypeTitle(workItemTypes.find((t) => t.value === token)) || token }}
        </span>
      </gl-intersperse>
      <template v-else>
        {{ activeTokenValue ? getTypeTitle(activeTokenValue) : inputValue }}
      </template>
    </template>
    <template #suggestions-list="{ suggestions, selections = [] }">
      <gl-filtered-search-suggestion
        v-for="type in suggestions"
        :key="type.value"
        :value="getTypeValue(type)"
      >
        <div
          class="gl-flex gl-items-center"
          :class="{ 'gl-pl-6': !selections.includes(type.value) }"
        >
          <gl-icon
            v-if="selections.includes(type.value)"
            name="check"
            class="gl-mr-3 gl-shrink-0"
            variant="subtle"
          />
          <div class="gl-flex gl-items-center">
            <gl-icon :name="type.icon" class="gl-mr-3 gl-shrink-0" />
            <div>{{ type.title }}</div>
          </div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
