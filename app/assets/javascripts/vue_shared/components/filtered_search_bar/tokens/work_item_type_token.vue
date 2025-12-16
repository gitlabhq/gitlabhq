<script>
import { GlIcon, GlIntersperse, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

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
      workItemTypes: this.config.initialWorkItemTypes || [],
      loading: false,
    };
  },
  methods: {
    getActiveType(types, data) {
      return types.find((type) => type.value === data);
    },
    getTypeValue(type) {
      return type?.value ?? '';
    },
    getTypeTitle(type) {
      return type?.title ?? '';
    },
    fetchWorkItemTypes() {
      if (!this.config.fetchWorkItemTypes) {
        return;
      }

      this.loading = true;
      this.config
        .fetchWorkItemTypes()
        .then((res) => {
          const rawTypes = Array.isArray(res) ? res : res.data?.workspace?.workItemTypes?.nodes;
          if (rawTypes) {
            this.workItemTypes = rawTypes.map((type) => ({
              value: type.name.toUpperCase().replace(/\s+/g, '_'), // 'Key Results' -> 'KEY_RESULTS'
              title: type.name,
            }));
          }
        })
        .catch(() =>
          createAlert({
            message: s__(
              'WorkItem|Something went wrong when fetching work item types. Please try again',
            ),
          }),
        )
        .finally(() => {
          this.loading = false;
        });
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
    :suggestions="workItemTypes"
    :get-active-token-value="getActiveType"
    :value-identifier="getTypeValue"
    v-bind="$attrs"
    @fetch-suggestions="fetchWorkItemTypes"
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
          <work-item-type-icon
            :work-item-type="type.title"
            :show-text="true"
            class="gl-whitespace-nowrap"
          />
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
