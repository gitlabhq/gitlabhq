<script>
import { GlButton, GlForm, GlLink, GlLoadingIcon, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

import { removeHierarchyChild } from '../graphql/cache_utils';
import groupWorkItemsQuery from '../graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '../graphql/project_work_items.query.graphql';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  SUPPORTED_PARENT_TYPE_MAP,
} from '../constants';

export default {
  inputId: 'work-item-parent-listbox-value',
  noWorkItemId: 'no-work-item-id',
  i18n: {
    assignParentLabel: s__('WorkItem|Assign parent'),
    parentLabel: s__('WorkItem|Parent'),
    none: s__('WorkItem|None'),
    noMatchingResults: s__('WorkItem|No matching results'),
    unAssign: s__('WorkItem|Unassign'),
    workItemsFetchError: s__(
      'WorkItem|Something went wrong while fetching items. Please try again.',
    ),
  },
  components: {
    GlButton,
    GlLoadingIcon,
    GlLink,
    GlForm,
    GlCollapsibleListbox,
  },
  inject: ['fullPath', 'isGroup'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    parent: {
      type: Object,
      required: false,
      default: null,
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: false,
      search: '',
      updateInProgress: false,
      searchStarted: false,
      availableWorkItems: [],
      localSelectedItem: this.parent?.id,
      oldParent: this.parent,
    };
  },
  computed: {
    hasParent() {
      return this.parent !== null;
    },
    isLoading() {
      return this.$apollo.queries.availableWorkItems.loading;
    },
    listboxText() {
      return (
        this.workItems.find(({ value }) => this.localSelectedItem === value)?.text ||
        this.parent?.title ||
        this.$options.i18n.none
      );
    },
    workItems() {
      return this.availableWorkItems.map(({ id, title }) => ({ text: title, value: id }));
    },
    parentType() {
      return SUPPORTED_PARENT_TYPE_MAP[this.workItemType];
    },
  },
  watch: {
    parent: {
      handler(newVal) {
        if (!this.isEditing) {
          this.localSelectedItem = newVal?.id;
        }
      },
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  apollo: {
    availableWorkItems: {
      query() {
        return this.isGroup ? groupWorkItemsQuery : projectWorkItemsQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.search,
          types: this.parentType,
          in: this.search ? 'TITLE' : undefined,
          iid: null,
          isNumber: false,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace.workItems.nodes.filter((wi) => this.workItemId !== wi.id) || [];
      },
      error() {
        this.$emit('error', this.$options.i18n.workItemsFetchError);
      },
    },
  },
  methods: {
    blurInput() {
      this.$refs.input.$el.blur();
    },
    handleFocus() {
      this.isEditing = true;
    },
    setSearchKey(value) {
      this.search = value;
    },
    async updateParent() {
      if (this.parent?.id === this.localSelectedItem) return;

      this.updateInProgress = true;
      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              hierarchyWidget: {
                parentId:
                  this.localSelectedItem === this.$options.noWorkItemId
                    ? null
                    : this.localSelectedItem,
              },
            },
          },
          update: (cache) =>
            removeHierarchyChild({
              cache,
              fullPath: this.fullPath,
              iid: this.oldParent?.iid,
              isGroup: this.isGroup,
              workItem: { id: this.workItemId },
            }),
        });

        if (errors.length) {
          this.$emit('error', errors.join('\n'));
          this.localSelectedItem = this.parent?.id || this.$options.noWorkItemId;
        }
      } catch (error) {
        this.$emit('error', sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType));
        Sentry.captureException(error);
      } finally {
        this.updateInProgress = false;
        this.isEditing = false;
      }
    },
    handleItemClick(item) {
      this.localSelectedItem = item;
      this.searchStarted = false;
      this.search = '';
      this.updateParent();
    },
    unassignParent() {
      this.localSelectedItem = this.$options.noWorkItemId;
      this.isEditing = false;
      this.updateParent();
    },
    onListboxShown() {
      this.searchStarted = true;
    },
    onListboxHide() {
      this.searchStarted = false;
      this.search = '';
      this.isEditing = false;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-align-items-center">
      <!-- hide header when editing, since we then have a form label. Keep it reachable for screenreader nav  -->
      <h3 :class="{ 'gl-sr-only': isEditing }" class="gl-mb-0! gl-heading-5">
        {{ __('Parent') }}
      </h3>
      <gl-loading-icon
        v-if="updateInProgress"
        data-testid="loading-icon-parent"
        size="sm"
        inline
        class="gl-ml-2 gl-my-0"
      />
      <gl-button
        v-if="canUpdate && !isEditing"
        data-testid="edit-parent"
        category="tertiary"
        size="small"
        class="gl-ml-auto"
        :disabled="updateInProgress"
        @click="isEditing = true"
        >{{ __('Edit') }}</gl-button
      >
    </div>
    <gl-form v-if="isEditing" class="gl-flex-nowrap" data-testid="work-item-parent-form">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <label :for="$options.inputId" class="gl-mb-0">{{ __('Parent') }}</label>
        <gl-button
          data-testid="apply-parent"
          category="tertiary"
          size="small"
          :disabled="updateInProgress"
          @click="isEditing = false"
          >{{ __('Apply') }}</gl-button
        >
      </div>
      <div>
        <!-- wrapper for the form input so the borders fit inside the sidebar -->
        <div class="gl-pr-2 gl-relative">
          <gl-collapsible-listbox
            id="$options.inputId"
            ref="input"
            class="gl-display-block"
            data-testid="work-item-parent-listbox"
            block
            searchable
            start-opened
            is-check-centered
            category="primary"
            fluid-width
            :searching="isLoading"
            :header-text="$options.i18n.assignParentLabel"
            :no-results-text="$options.i18n.noMatchingResults"
            :loading="updateInProgress"
            :items="workItems"
            :toggle-text="listboxText"
            :selected="localSelectedItem"
            :reset-button-label="$options.i18n.unAssign"
            @reset="unassignParent"
            @search="debouncedSearchKeyUpdate"
            @select="handleItemClick"
            @shown="onListboxShown"
            @hidden="onListboxHide"
          >
            <template #list-item="{ item }">
              <div @click="handleItemClick(item.value, $event)">
                {{ item.text }}
              </div>
            </template>
          </gl-collapsible-listbox>
        </div>
      </div>
    </gl-form>
    <template v-else-if="hasParent">
      <gl-link
        data-testid="work-item-parent-link"
        class="gl-link gl-text-gray-900 gl-display-inline-block gl-max-w-full gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
        :href="parent.webUrl"
        >{{ listboxText }}</gl-link
      >
    </template>
    <template v-else>
      <div data-testid="work-item-parent-none" class="gl-text-secondary">{{ __('None') }}</div>
    </template>
  </div>
</template>
