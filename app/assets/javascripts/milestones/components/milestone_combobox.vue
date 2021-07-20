<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlIcon,
} from '@gitlab/ui';
import { debounce, isEqual } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__, __, sprintf } from '~/locale';
import createStore from '../stores';
import MilestoneResultsSection from './milestone_results_section.vue';

const SEARCH_DEBOUNCE_MS = 250;

export default {
  name: 'MilestoneCombobox',
  store: createStore(),
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlIcon,
    MilestoneResultsSection,
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
  data() {
    return {
      searchQuery: '',
    };
  },
  translations: {
    milestone: s__('MilestoneCombobox|Milestone'),
    selectMilestone: s__('MilestoneCombobox|Select milestone'),
    noMilestone: s__('MilestoneCombobox|No milestone'),
    noResultsLabel: s__('MilestoneCombobox|No matching results'),
    searchMilestones: s__('MilestoneCombobox|Search Milestones'),
    searchErrorMessage: s__('MilestoneCombobox|An error occurred while searching for milestones'),
    projectMilestones: s__('MilestoneCombobox|Project milestones'),
    groupMilestones: s__('MilestoneCombobox|Group milestones'),
  },
  computed: {
    ...mapState(['matches', 'selectedMilestones']),
    ...mapGetters(['isLoading', 'groupMilestonesEnabled']),
    selectedMilestonesLabel() {
      const { selectedMilestones } = this;
      const firstMilestoneName = selectedMilestones[0];

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
    showProjectMilestoneSection() {
      return Boolean(
        this.matches.projectMilestones.totalCount > 0 || this.matches.projectMilestones.error,
      );
    },
    showGroupMilestoneSection() {
      return (
        this.groupMilestonesEnabled &&
        Boolean(this.matches.groupMilestones.totalCount > 0 || this.matches.groupMilestones.error)
      );
    },
    showNoResults() {
      return !this.showProjectMilestoneSection && !this.showGroupMilestoneSection;
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
    // made inaccessible by Vue. More info:
    // https://stackoverflow.com/a/52988020/1063392
    this.debouncedSearch = debounce(function search() {
      this.search(this.searchQuery);
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
      'toggleMilestones',
      'search',
      'fetchMilestones',
    ]),
    focusSearchBox() {
      this.$refs.searchBox.$el.querySelector('input').focus();
    },
    onSearchBoxEnter() {
      this.debouncedSearch.cancel();
      this.search(this.searchQuery);
    },
    onSearchBoxInput() {
      this.debouncedSearch();
    },
    selectMilestone(milestone) {
      this.toggleMilestones(milestone);
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
  <gl-dropdown v-bind="$attrs" class="milestone-combobox" @shown="focusSearchBox">
    <template #button-content>
      <span data-testid="milestone-combobox-button-content" class="gl-flex-grow-1 text-muted">{{
        selectedMilestonesLabel
      }}</span>
      <gl-icon name="chevron-down" />
    </template>

    <gl-dropdown-section-header>
      <span class="text-center d-block">{{ $options.translations.selectMilestone }}</span>
    </gl-dropdown-section-header>

    <gl-dropdown-divider />

    <gl-search-box-by-type
      ref="searchBox"
      v-model.trim="searchQuery"
      class="gl-m-3"
      :placeholder="this.$options.translations.searchMilestones"
      @input="onSearchBoxInput"
      @keydown.enter.prevent="onSearchBoxEnter"
    />

    <gl-dropdown-item @click="selectNoMilestone()">
      <span :class="{ 'gl-pl-6': true, 'selected-item': selectedMilestones.length === 0 }">
        {{ $options.translations.noMilestone }}
      </span>
    </gl-dropdown-item>

    <gl-dropdown-divider />

    <template v-if="isLoading">
      <gl-loading-icon size="sm" />
      <gl-dropdown-divider />
    </template>
    <template v-else-if="showNoResults">
      <div class="dropdown-item-space">
        <span data-testid="milestone-combobox-no-results" class="gl-pl-6">{{
          $options.translations.noResultsLabel
        }}</span>
      </div>
      <gl-dropdown-divider />
    </template>
    <template v-else>
      <milestone-results-section
        v-if="showProjectMilestoneSection"
        :section-title="$options.translations.projectMilestones"
        :total-count="matches.projectMilestones.totalCount"
        :items="matches.projectMilestones.list"
        :selected-milestones="selectedMilestones"
        :error="matches.projectMilestones.error"
        :error-message="$options.translations.searchErrorMessage"
        data-testid="project-milestones-section"
        @selected="selectMilestone($event)"
      />

      <milestone-results-section
        v-if="showGroupMilestoneSection"
        :section-title="$options.translations.groupMilestones"
        :total-count="matches.groupMilestones.totalCount"
        :items="matches.groupMilestones.list"
        :selected-milestones="selectedMilestones"
        :error="matches.groupMilestones.error"
        :error-message="$options.translations.searchErrorMessage"
        data-testid="group-milestones-section"
        @selected="selectMilestone($event)"
      />
    </template>
    <gl-dropdown-item
      v-for="(item, idx) in extraLinks"
      :key="idx"
      :href="item.url"
      data-testid="milestone-combobox-extra-links"
    >
      <span class="gl-pl-6">{{ item.text }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
