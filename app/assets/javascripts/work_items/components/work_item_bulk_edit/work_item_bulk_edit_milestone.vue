<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash';
import { createAlert } from '~/alert';
import { MILESTONE_STATE } from '~/sidebar/constants';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import groupMilestonesQuery from '~/sidebar/queries/group_milestones.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import { BULK_EDIT_NO_VALUE } from '../../constants';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: false,
      default: undefined,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchStarted: false,
      searchTerm: '',
      selectedId: this.value,
      milestones: [],
      milestonesCache: [],
    };
  },
  apollo: {
    milestones: {
      query() {
        return this.isGroup ? groupMilestonesQuery : projectMilestonesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          title: this.searchTerm,
          state: MILESTONE_STATE.ACTIVE,
          first: 20,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.attributes.nodes ?? [];
      },
      error(error) {
        createAlert({
          message: __('Failed to load milestones. Please try again.'),
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.milestones.loading;
    },
    listboxItems() {
      if (!this.searchTerm.trim().length) {
        return [
          {
            text: s__('WorkItem|No milestone'),
            textSrOnly: true,
            options: [{ text: s__('WorkItem|No milestone'), value: BULK_EDIT_NO_VALUE }],
          },
          {
            text: __('All'),
            textSrOnly: true,
            options: this.milestones.map(({ id, title, expired }) => ({
              value: id,
              text: title,
              expired,
            })),
          },
        ];
      }

      return this.milestones.map(({ id, title, expired }) => ({
        value: id,
        text: title,
        expired,
      }));
    },
    selectedMilestone() {
      return this.milestonesCache.find((milestone) => this.selectedId === milestone.id);
    },
    toggleText() {
      if (this.selectedMilestone) {
        return this.selectedMilestone.title;
      }
      if (this.selectedId === BULK_EDIT_NO_VALUE) {
        return s__('WorkItem|No milestone');
      }
      return __('Select milestone');
    },
  },
  watch: {
    milestones(milestones) {
      this.updateMilestonesCache(milestones);
    },
  },
  created() {
    this.setSearchTermDebounced = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    clearSearch() {
      this.searchTerm = '';
      this.$refs.listbox.$refs.searchBox.clearInput?.();
    },
    handleSelect(item) {
      this.selectedId = item;
      this.$emit('input', item);
      this.clearSearch();
    },
    handleShown() {
      this.searchTerm = '';
      this.searchStarted = true;
    },
    reset() {
      this.handleSelect(undefined);
      this.$refs.listbox.close();
    },
    setSearchTerm(searchTerm) {
      this.searchTerm = searchTerm;
    },
    updateMilestonesCache(milestones) {
      // Need to store all milestones we encounter so we can show "Selected" milestones
      // even if they're not found in the apollo `milestones` list
      this.milestonesCache = unionBy(this.milestonesCache, milestones, 'id');
    },
    itemExpiredText(item) {
      return item.expired ? ` ${__('(expired)')}` : '';
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Milestone')">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="__('Select milestone')"
      is-check-centered
      :items="listboxItems"
      :no-results-text="s__('WorkItem|No matching results')"
      :reset-button-label="__('Reset')"
      searchable
      :searching="isLoading"
      :selected="selectedId"
      :toggle-text="toggleText"
      :disabled="disabled"
      @reset="reset"
      @search="setSearchTermDebounced"
      @select="handleSelect"
      @shown="handleShown"
    >
      <template #list-item="{ item }">
        <div>{{ item.text }}{{ itemExpiredText(item) }}</div>
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
