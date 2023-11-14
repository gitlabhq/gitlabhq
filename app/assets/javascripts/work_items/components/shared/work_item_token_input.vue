<script>
import { GlTokenSelector, GlAlert } from '@gitlab/ui';
import { debounce } from 'lodash';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isNumeric } from '~/lib/utils/number_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { highlighter } from 'ee_else_ce/gfm_auto_complete';

import groupWorkItemsQuery from '../../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import {
  WORK_ITEMS_TYPE_MAP,
  I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER,
  I18N_WORK_ITEM_SEARCH_ERROR,
  sprintfWorkItem,
} from '../../constants';

export default {
  components: {
    GlTokenSelector,
    GlAlert,
  },
  directives: { SafeHtml },
  inject: ['isGroup'],
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    fullPath: {
      type: String,
      required: true,
    },
    childrenType: {
      type: String,
      required: false,
      default: '',
    },
    childrenIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    parentWorkItemId: {
      type: String,
      required: true,
    },
    areWorkItemsToAddValid: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    availableWorkItems: {
      query() {
        return this.isGroup ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: '',
          types: this.childrenType ? [this.childrenType] : [],
          isNumber: false,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return [
          ...this.filterItems(data.workspace.workItemsByIid?.nodes),
          ...this.filterItems(data.workspace.workItems.nodes),
        ];
      },
      error() {
        this.error = sprintfWorkItem(I18N_WORK_ITEM_SEARCH_ERROR, this.childrenTypeName);
      },
    },
  },
  data() {
    return {
      availableWorkItems: [],
      query: '',
      searchStarted: false,
      error: '',
    };
  },
  computed: {
    workItemsToAdd: {
      get() {
        return this.value;
      },
      set(workItemsToAdd) {
        this.$emit('input', workItemsToAdd);
      },
    },
    isLoading() {
      return this.$apollo.queries.availableWorkItems.loading;
    },
    addInputPlaceholder() {
      return sprintfWorkItem(I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER, this.childrenTypeName);
    },
    childrenTypeName() {
      return WORK_ITEMS_TYPE_MAP[this.childrenType]?.name;
    },
    tokenSelectorContainerClass() {
      return !this.areWorkItemsToAddValid ? 'gl-inset-border-1-red-500!' : '';
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getIdFromGraphQLId,
    setSearchKey(value) {
      this.query = value;

      // Query parameters for searching by text
      const variables = {
        searchTerm: value,
        in: value ? 'TITLE' : undefined,
        iid: null,
        isNumber: false,
      };

      // Check if it is a number, add iid as query parameter
      if (isNumeric(value) && value) {
        variables.iid = value;
        variables.isNumber = true;
      }

      // Fetch combined results of search by iid and search by title.
      this.$apollo.queries.availableWorkItems.refetch(variables);
    },
    handleFocus() {
      this.searchStarted = true;
      this.$emit('searching', true);
    },
    handleMouseOver() {
      this.timeout = setTimeout(() => {
        this.searchStarted = true;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    handleMouseOut() {
      clearTimeout(this.timeout);
    },
    handleBlur() {
      this.$emit('searching', false);
    },
    focusInputText() {
      this.$nextTick(() => {
        if (this.areWorkItemsToAddValid) {
          this.$refs.tokenSelector.$el.querySelector('input[type="text"]').focus();
        }
      });
    },
    formatResults(input) {
      if (!this.query) {
        return input;
      }

      return highlighter(`<span class="gl-text-black-normal">${input}</span>`, this.query);
    },
    unsetError() {
      this.error = '';
    },
    filterItems(items) {
      return (
        items?.filter(
          (wi) => !this.childrenIds.includes(wi.id) && this.parentWorkItemId !== wi.id,
        ) || []
      );
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error" variant="danger" class="gl-mb-3" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <gl-token-selector
      ref="tokenSelector"
      v-model="workItemsToAdd"
      :dropdown-items="availableWorkItems"
      :loading="isLoading"
      :placeholder="addInputPlaceholder"
      menu-class="gl-dropdown-menu-wide dropdown-reduced-height gl-min-h-7!"
      :container-class="tokenSelectorContainerClass"
      data-testid="work-item-token-select-input"
      @text-input="debouncedSearchKeyUpdate"
      @focus="handleFocus"
      @mouseover.native="handleMouseOver"
      @mouseout.native="handleMouseOut"
      @token-add="focusInputText"
      @token-remove="focusInputText"
      @blur="handleBlur"
    >
      <template #token-content="{ token }"> {{ token.iid }} {{ token.title }} </template>
      <template #dropdown-item-content="{ dropdownItem }">
        <div class="gl-display-flex">
          <div
            v-safe-html="formatResults(dropdownItem.iid)"
            class="gl-text-secondary gl-font-sm gl-mr-4"
          ></div>
          <div v-safe-html="formatResults(dropdownItem.title)" class="gl-text-truncate"></div>
        </div>
      </template>
    </gl-token-selector>
  </div>
</template>
