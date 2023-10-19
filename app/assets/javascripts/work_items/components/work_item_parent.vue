<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { debounce } from 'lodash';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

import projectWorkItemsQuery from '../graphql/project_work_items.query.graphql';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
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
  inject: ['fullPath'],
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
      isNotFocused: true,
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
    listboxCategory() {
      return this.searchStarted ? 'secondary' : 'tertiary';
    },
    listboxClasses() {
      return {
        'is-not-focused': this.isNotFocused && !this.searchStarted,
      };
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
      query: projectWorkItemsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.search,
          types: [WORK_ITEM_TYPE_ENUM_OBJECTIVE],
          in: this.search ? 'TITLE' : undefined,
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
      this.isNotFocused = false;
    },
    onListboxHide() {
      this.searchStarted = false;
      this.search = '';
      this.isNotFocused = true;
    },
    setListboxFocused() {
      // This is to match the caret behaviour of parent listbox
      // to the other dropdown fields of work items
      if (document.activeElement.parentElement.id !== 'work-item-parent-listbox-value') {
        this.isNotFocused = true;
      }
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
    <div
      v-else
      :class="{ 'gl-max-w-max-content': !workItemsMvc2Enabled }"
      @mouseover="isNotFocused = false"
      @mouseleave="setListboxFocused"
      @focusout="isNotFocused = true"
      @focusin="isNotFocused = false"
    >
      <gl-collapsible-listbox
        id="work-item-parent-listbox-value"
        class="gl-max-w-max-content"
        data-testid="work-item-parent-listbox"
        block
        searchable
        :no-caret="isNotFocused && !searchStarted"
        is-check-centered
        :category="listboxCategory"
        :searching="isLoading"
        :header-text="$options.i18n.assignParentLabel"
        :no-results-text="$options.i18n.noMatchingResults"
        :loading="updateInProgress"
        :items="workItems"
        :toggle-text="listboxText"
        :toggle-class="listboxClasses"
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
