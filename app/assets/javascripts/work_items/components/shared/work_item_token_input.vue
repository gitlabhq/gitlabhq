<script>
import { GlTokenSelector, GlAlert } from '@gitlab/ui';
import { debounce } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isNumeric } from '~/lib/utils/number_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isSafeURL } from '~/lib/utils/url_utility';

import { highlighter } from 'ee_else_ce/gfm_auto_complete';

import groupWorkItemsQuery from '../../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '../../graphql/work_items_by_references.query.graphql';
import {
  WORK_ITEMS_TYPE_MAP,
  I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER,
  I18N_WORK_ITEM_SEARCH_ERROR,
  I18N_WORK_ITEM_NO_MATCHES_FOUND,
  sprintfWorkItem,
} from '../../constants';
import { isReference } from '../../utils';

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
    workspaceWorkItems: {
      query() {
        return this.isGroup ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        return this.queryVariables;
      },
      skip() {
        return !this.searchStarted || this.isSearchingByReference;
      },
      update(data) {
        return [
          ...this.filterItems(data.workspace.workItemsByIid?.nodes),
          ...this.filterItems(data.workspace.workItems?.nodes),
        ];
      },
      error() {
        this.error = sprintfWorkItem(I18N_WORK_ITEM_SEARCH_ERROR, this.childrenTypeName);
      },
    },
    workItemsByReference: {
      query: workItemsByReferencesQuery,
      variables() {
        return {
          contextNamespacePath: this.fullPath,
          refs: [this.searchTerm],
        };
      },
      skip() {
        return !this.isSearchingByReference;
      },
      update(data) {
        return data.workItemsByReference.nodes;
      },
      error() {
        this.error = sprintfWorkItem(I18N_WORK_ITEM_SEARCH_ERROR, this.childrenTypeName);
      },
    },
  },
  data() {
    return {
      workspaceWorkItems: [],
      searchTerm: '',
      searchStarted: false,
      error: '',
      textInputAttrs: {
        class: 'gl-min-w-fit-content!',
      },
    };
  },
  computed: {
    availableWorkItems() {
      return this.isSearchingByReference ? this.workItemsByReference : this.workspaceWorkItems;
    },
    isSearchingByReference() {
      return isReference(this.searchTerm) || isSafeURL(this.searchTerm);
    },
    workItemsToAdd: {
      get() {
        return this.value;
      },
      set(workItemsToAdd) {
        this.$emit('input', workItemsToAdd);
      },
    },
    isLoading() {
      return (
        this.$apollo.queries.workspaceWorkItems.loading ||
        this.$apollo.queries.workItemsByReference.loading
      );
    },
    childrenTypeName() {
      return WORK_ITEMS_TYPE_MAP[this.childrenType]?.name;
    },
    tokenSelectorContainerClass() {
      return !this.areWorkItemsToAddValid ? 'gl-inset-border-1-red-500!' : '';
    },
    queryVariables() {
      return {
        fullPath: this.fullPath,
        searchTerm: this.searchTerm,
        types: this.childrenType ? [this.childrenType] : [],
        in: this.searchTerm ? 'TITLE' : undefined,
        iid: isNumeric(this.searchTerm) ? this.searchTerm : null,
        searchByIid: isNumeric(this.searchTerm),
        searchByText: true,
      };
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getIdFromGraphQLId,
    async setSearchKey(value) {
      this.searchTerm = value;
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
          this.$refs.tokenSelector.focusTextInput();
        }
      });
    },
    formatResults(input) {
      if (!this.searchTerm) {
        return input;
      }

      return highlighter(`<span class="gl-text-black-normal">${input}</span>`, this.searchTerm);
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
  i18n: {
    noMatchesFoundMessage: I18N_WORK_ITEM_NO_MATCHES_FOUND,
    addInputPlaceholder: I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER,
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
      :placeholder="$options.i18n.addInputPlaceholder"
      menu-class="gl-dropdown-menu-wide dropdown-reduced-height gl-min-h-7!"
      :container-class="tokenSelectorContainerClass"
      data-testid="work-item-token-select-input"
      :text-input-attrs="textInputAttrs"
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
      <template #no-results-content>
        <span data-testid="no-match-found-namespace-message">{{
          $options.i18n.noMatchesFoundMessage
        }}</span>
      </template>
    </gl-token-selector>
  </div>
</template>
