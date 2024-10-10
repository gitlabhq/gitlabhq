<script>
import { GlBadge, GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce, isEqual } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__, __, sprintf } from '~/locale';
import createStore from '../stores';

const SEARCH_DEBOUNCE_MS = 250;

export default {
  name: 'MilestoneCombobox',
  store: createStore(),
  components: {
    GlCollapsibleListbox,
    GlBadge,
    GlButton,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    projectId: {
      type: String,
      required: true,
    },
    groupId: {
      type: String,
      required: false,
      default: '',
    },
    groupMilestonesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    extraLinks: {
      type: Array,
      default: () => [],
      required: false,
    },
  },
  translations: {
    selectMilestone: s__('MilestoneCombobox|Select milestone'),
    noMilestone: s__('MilestoneCombobox|No milestone'),
    projectMilestones: s__('MilestoneCombobox|Project milestones'),
    groupMilestones: s__('MilestoneCombobox|Group milestones'),
    unselect: __('Unselect'),
  },
  computed: {
    ...mapState(['matches', 'selectedMilestones']),
    ...mapGetters(['isLoading']),
    allMilestones() {
      const { groupMilestones, projectMilestones } = this.matches || {};
      const milestones = [];

      if (projectMilestones?.totalCount) {
        milestones.push({
          id: 'project-milestones',
          text: this.$options.translations.projectMilestones,
          options: projectMilestones.list,
          totalCount: projectMilestones.totalCount,
        });
      }

      if (groupMilestones?.totalCount) {
        milestones.push({
          id: 'group-milestones',
          text: this.$options.translations.groupMilestones,
          options: groupMilestones.list,
          totalCount: groupMilestones.totalCount,
        });
      }

      return milestones;
    },
    selectedMilestonesLabel() {
      const { selectedMilestones } = this;
      const [firstMilestoneName] = selectedMilestones;

      if (selectedMilestones.length === 0) {
        return this.$options.translations.noMilestone;
      }

      if (selectedMilestones.length === 1) {
        return firstMilestoneName;
      }

      const numberOfOtherMilestones = selectedMilestones.length - 1;
      return sprintf(__('%{firstMilestoneName} + %{numberOfOtherMilestones} more'), {
        firstMilestoneName,
        numberOfOtherMilestones,
      });
    },
  },
  watch: {
    // Keep the Vuex store synchronized if the parent
    // component updates the selected milestones through v-model
    value: {
      immediate: true,
      handler() {
        const milestoneTitles = this.value.map((milestone) =>
          milestone.title ? milestone.title : milestone,
        );
        if (!isEqual(milestoneTitles, this.selectedMilestones)) {
          this.setSelectedMilestones(milestoneTitles);
        }
      },
    },
  },
  created() {
    // This method is defined here instead of in `methods`
    // because we need to access the .cancel() method
    // lodash attaches to the function, which is
    // made inaccessible by Vue.
    this.debouncedSearch = debounce(function search(q) {
      this.search(q);
    }, SEARCH_DEBOUNCE_MS);

    this.setProjectId(this.projectId);
    this.setGroupId(this.groupId);
    this.setGroupMilestonesAvailable(this.groupMilestonesAvailable);
    this.fetchMilestones();
  },
  methods: {
    ...mapActions([
      'setProjectId',
      'setGroupId',
      'setGroupMilestonesAvailable',
      'setSelectedMilestones',
      'clearSelectedMilestones',
      'search',
      'fetchMilestones',
    ]),
    onSearchBoxInput(q) {
      this.debouncedSearch(q);
    },
    selectMilestone(milestones) {
      this.setSelectedMilestones(milestones);
      this.$emit('input', this.selectedMilestones);
    },
    selectNoMilestone() {
      this.clearSelectedMilestones();
      this.$emit('input', this.selectedMilestones);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="$options.translations.selectMilestone"
    :items="allMilestones"
    :reset-button-label="$options.translations.unselect"
    :searching="isLoading"
    :selected="selectedMilestones"
    :toggle-text="selectedMilestonesLabel"
    block
    multiple
    searchable
    @reset="selectNoMilestone"
    @search="onSearchBoxInput"
    @select="selectMilestone"
  >
    <template #group-label="{ group }">
      <span :data-testid="`${group.id}-section`"
        >{{ group.text }}<gl-badge class="gl-ml-2">{{ group.totalCount }}</gl-badge></span
      >
    </template>
    <template #footer>
      <div
        class="gl-flex gl-flex-col gl-border-t-1 gl-border-t-dropdown !gl-p-2 !gl-pt-0 gl-border-t-solid"
      >
        <gl-button
          v-for="(item, idx) in extraLinks"
          :key="idx"
          :href="item.url"
          is-check-item
          data-testid="milestone-combobox-extra-links"
          category="tertiary"
          block
          class="!gl-mt-2 !gl-justify-start"
        >
          {{ item.text }}
        </gl-button>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
