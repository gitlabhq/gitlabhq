<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
    GlFormGroup,
    GlCollapsibleListbox,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath', 'isGroup'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    parent: {
      type: Object,
      required: false,
      default: () => {},
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
      search: '',
      updateInProgress: false,
      searchStarted: false,
      availableWorkItems: [],
      localSelectedItem: this.parent?.id,
      oldParent: this.parent,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.availableWorkItems.loading;
    },
    listboxText() {
      return (
        this.workItems.filter((item) => this.localSelectedItem === item.value)?.[0]?.text ||
        this.parent?.title ||
        this.$options.i18n.none
      );
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
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
        this.localSelectedItem = newVal?.id;
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
          searchByIid: false,
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
    setSearchKey(value) {
      this.search = value;
    },
    async updateParent() {
      if (this.parent?.id === this.localSelectedItem) {
        return;
      }
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
                  this.localSelectedItem === 'no-work-item-id' ? null : this.localSelectedItem,
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
          this.localSelectedItem = this.parent?.id || 'no-work-item-id';
        }
      } catch (error) {
        this.$emit('error', sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType));
        Sentry.captureException(error);
      } finally {
        this.updateInProgress = false;
      }
    },
    handleItemClick(item) {
      this.localSelectedItem = item;
      this.searchStarted = false;
      this.search = '';
      this.updateParent();
    },
    unAssignParent() {
      this.localSelectedItem = 'no-work-item-id';
      this.updateParent();
    },
    onListboxShown() {
      this.searchStarted = true;
    },
    onListboxHide() {
      this.searchStarted = false;
      this.search = '';
    },
  },
};
</script>

<template>
  <gl-form-group
    class="work-item-dropdown gl-flex-nowrap"
    data-testid="work-item-parent-form"
    :label="$options.i18n.parentLabel"
    label-for="work-item-parent-listbox-value"
    label-class="gl-pb-0! gl-mt-3 gl-overflow-wrap-break work-item-field-label"
    label-cols="3"
    label-cols-lg="2"
  >
    <span
      v-if="!canUpdate"
      class="gl-text-secondary gl-ml-4 gl-mt-3 gl-display-inline-block gl-line-height-normal work-item-field-value"
      data-testid="disabled-text"
    >
      {{ listboxText }}
    </span>
    <div v-else :class="{ 'gl-max-w-max-content': !workItemsMvc2Enabled }">
      <gl-collapsible-listbox
        id="work-item-parent-listbox-value"
        class="gl-max-w-max-content"
        data-testid="work-item-parent-listbox"
        block
        searchable
        is-check-centered
        category="tertiary"
        :searching="isLoading"
        :header-text="$options.i18n.assignParentLabel"
        :no-results-text="$options.i18n.noMatchingResults"
        :loading="updateInProgress"
        :items="workItems"
        :toggle-text="listboxText"
        :selected="localSelectedItem"
        :reset-button-label="$options.i18n.unAssign"
        @reset="unAssignParent"
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
  </gl-form-group>
</template>
