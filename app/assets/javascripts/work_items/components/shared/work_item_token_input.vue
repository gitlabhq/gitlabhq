<script>
import { GlTokenSelector, GlAlert } from '@gitlab/ui';
import { debounce, escape } from 'lodash';

import { isNumeric } from '~/lib/utils/number_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isValidURL } from '~/lib/utils/url_utility';
import { highlighter } from 'ee_else_ce/gfm_auto_complete';
import workItemAncestorsQuery from '../../graphql/work_item_ancestors.query.graphql';

import groupWorkItemsQuery from '../../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '../../graphql/work_items_by_references.query.graphql';
import {
  I18N_WORK_ITEM_SEARCH_ERROR,
  NAME_TO_ENUM_MAP,
  NAME_TO_TEXT_LOWERCASE_MAP,
} from '../../constants';
import { formatAncestors, isReference } from '../../utils';

export default {
  components: {
    GlTokenSelector,
    GlAlert,
  },
  directives: { SafeHtml },
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
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
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
          ...this.filterItems(data.workspace?.workItemsByIid?.nodes || []),
          ...this.filterItems(data.workspace?.workItems?.nodes || []),
        ];
      },
      error() {
        this.error = sprintf(I18N_WORK_ITEM_SEARCH_ERROR, {
          workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.childrenType],
        });
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
        return this.filterItems(data.workItemsByReference.nodes);
      },
      error() {
        this.error = sprintf(I18N_WORK_ITEM_SEARCH_ERROR, {
          workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.childrenType],
        });
      },
    },
    ancestorIds: {
      query: workItemAncestorsQuery,
      variables() {
        return {
          id: this.parentWorkItemId,
        };
      },
      update(data) {
        return formatAncestors(data.workItem).flatMap((ancestor) => [ancestor.id]);
      },
      skip() {
        return !this.parentWorkItemId;
      },
    },
  },
  data() {
    return {
      ancestorIds: [],
      workspaceWorkItems: [],
      workItemsByReference: [],
      searchTerm: '',
      searchStarted: false,
      error: '',
      textInputAttrs: {
        class: '!gl-min-w-fit',
      },
    };
  },
  computed: {
    availableWorkItems() {
      return this.isSearchingByReference ? this.workItemsByReference : this.workspaceWorkItems;
    },
    isSearchingByReference() {
      return isReference(this.searchTerm) || isValidURL(this.searchTerm);
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
    tokenSelectorContainerClass() {
      return !this.areWorkItemsToAddValid ? '!gl-shadow-inner-1-red-500' : '';
    },
    queryVariables() {
      const variables = {
        fullPath: this.fullPath,
        searchTerm: this.searchTerm,
        types: this.childrenType ? [NAME_TO_ENUM_MAP[this.childrenType]] : [],
        in: this.searchTerm ? 'TITLE' : undefined,
        iid: isNumeric(this.searchTerm) ? this.searchTerm : null,
        searchByIid: isNumeric(this.searchTerm),
        searchByText: true,
      };

      if (this.isGroup) {
        variables.includeAncestors = true;
        variables.includeDescendants = true;
      }

      return variables;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
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
      const escapedInput = escape(input);

      if (!this.searchTerm) {
        return escapedInput;
      }

      return highlighter(`<span class="gl-text-default">${escapedInput}</span>`, this.searchTerm);
    },
    unsetError() {
      this.error = '';
    },
    filterItems(items) {
      return (
        items?.filter((wi) => {
          return (
            !this.childrenIds.includes(wi.id) &&
            this.parentWorkItemId !== wi.id &&
            !this.ancestorIds.includes(wi.id)
          );
        }) || []
      );
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['strong', 'span'] },
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
      :aria-label="s__('WorkItem|Search existing items or enter an item\'s URL or reference ID')"
      :dropdown-items="availableWorkItems"
      :loading="isLoading"
      :placeholder="s__('WorkItem|Search existing items or enter an item\'s URL or reference ID')"
      menu-class="gl-dropdown-menu-wide dropdown-reduced-height !gl-min-h-7"
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
        <div class="gl-flex">
          <div
            v-safe-html:[$options.safeHtmlConfig]="formatResults(dropdownItem.iid)"
            class="gl-mr-4 gl-text-sm gl-text-subtle"
          ></div>
          <div
            v-safe-html:[$options.safeHtmlConfig]="formatResults(dropdownItem.title)"
            class="gl-truncate"
          ></div>
        </div>
      </template>
      <template #no-results-content>
        <span data-testid="no-match-found-namespace-message">{{
          s__('WorkItem|No matches found')
        }}</span>
      </template>
    </gl-token-selector>
  </div>
</template>
