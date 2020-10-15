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
import { intersection, debounce } from 'lodash';
import { __, sprintf } from '~/locale';
import Api from '~/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';

const SEARCH_DEBOUNCE_MS = 250;

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlIcon,
  },
  model: {
    prop: 'preselectedMilestones',
    event: 'change',
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    preselectedMilestones: {
      type: Array,
      default: () => [],
      required: false,
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
      projectMilestones: [],
      searchResults: [],
      selectedMilestones: [],
      requestCount: 0,
    };
  },
  translations: {
    milestone: __('Milestone'),
    selectMilestone: __('Select milestone'),
    noMilestone: __('No milestone'),
    noResultsLabel: __('No matching results'),
    searchMilestones: __('Search Milestones'),
  },
  computed: {
    selectedMilestonesLabel() {
      if (this.milestoneTitles.length === 1) {
        return this.milestoneTitles[0];
      }

      if (this.milestoneTitles.length > 1) {
        const firstMilestoneName = this.milestoneTitles[0];
        const numberOfOtherMilestones = this.milestoneTitles.length - 1;
        return sprintf(__('%{firstMilestoneName} + %{numberOfOtherMilestones} more'), {
          firstMilestoneName,
          numberOfOtherMilestones,
        });
      }

      return this.$options.translations.noMilestone;
    },
    milestoneTitles() {
      return this.preselectedMilestones.map(milestone => milestone.title);
    },
    dropdownItems() {
      return this.searchResults.length ? this.searchResults : this.projectMilestones;
    },
    noResults() {
      return this.searchQuery.length > 2 && this.searchResults.length === 0;
    },
    isLoading() {
      return this.requestCount !== 0;
    },
  },
  created() {
    // This method is defined here instead of in `methods`
    // because we need to access the .cancel() method
    // lodash attaches to the function, which is
    // made inaccessible by Vue. More info:
    // https://stackoverflow.com/a/52988020/1063392
    this.debouncedSearchMilestones = debounce(this.searchMilestones, SEARCH_DEBOUNCE_MS);
  },
  mounted() {
    this.fetchMilestones();
  },
  methods: {
    focusSearchBox() {
      this.$refs.searchBox.$el.querySelector('input').focus();
    },
    fetchMilestones() {
      this.requestCount += 1;

      Api.projectMilestones(this.projectId)
        .then(({ data }) => {
          this.projectMilestones = this.getTitles(data);
          this.selectedMilestones = intersection(this.projectMilestones, this.milestoneTitles);
        })
        .catch(() => {
          createFlash(__('An error occurred while loading milestones'));
        })
        .finally(() => {
          this.requestCount -= 1;
        });
    },
    searchMilestones() {
      this.requestCount += 1;
      const options = {
        search: this.searchQuery,
        scope: 'milestones',
      };

      if (this.searchQuery.length < 3) {
        this.requestCount -= 1;
        this.searchResults = [];
        return;
      }

      Api.projectSearch(this.projectId, options)
        .then(({ data }) => {
          const searchResults = this.getTitles(data);

          this.searchResults = searchResults.length ? searchResults : [];
        })
        .catch(() => {
          createFlash(__('An error occurred while searching for milestones'));
        })
        .finally(() => {
          this.requestCount -= 1;
        });
    },
    onSearchBoxInput() {
      this.debouncedSearchMilestones();
    },
    onSearchBoxEnter() {
      this.debouncedSearchMilestones.cancel();
      this.searchMilestones();
    },
    toggleMilestoneSelection(clickedMilestone) {
      if (!clickedMilestone) return [];

      let milestones = [...this.preselectedMilestones];
      const hasMilestone = this.milestoneTitles.includes(clickedMilestone);

      if (hasMilestone) {
        milestones = milestones.filter(({ title }) => title !== clickedMilestone);
      } else {
        milestones.push({ title: clickedMilestone });
      }

      return milestones;
    },
    onMilestoneClicked(clickedMilestone) {
      const milestones = this.toggleMilestoneSelection(clickedMilestone);
      this.$emit('change', milestones);

      this.selectedMilestones = intersection(
        this.projectMilestones,
        milestones.map(milestone => milestone.title),
      );
    },
    isSelectedMilestone(milestoneTitle) {
      return this.selectedMilestones.includes(milestoneTitle);
    },
    getTitles(milestones) {
      return milestones.filter(({ state }) => state === 'active').map(({ title }) => title);
    },
  },
};
</script>

<template>
  <gl-dropdown v-bind="$attrs" class="project-milestone-combobox" @shown="focusSearchBox">
    <template slot="button-content">
      <span ref="buttonText" class="flex-grow-1 ml-1 text-muted">{{
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
      :placeholder="this.$options.translations.searchMilestones"
      @input="onSearchBoxInput"
      @keydown.enter.prevent="onSearchBoxEnter"
    />

    <gl-dropdown-item @click="onMilestoneClicked(null)">
      <span :class="{ 'pl-4': true, 'selected-item': selectedMilestones.length === 0 }">
        {{ $options.translations.noMilestone }}
      </span>
    </gl-dropdown-item>

    <gl-dropdown-divider />

    <template v-if="isLoading">
      <gl-loading-icon />
      <gl-dropdown-divider />
    </template>
    <template v-else-if="noResults">
      <div class="dropdown-item-space">
        <span ref="noResults" class="pl-4">{{ $options.translations.noResultsLabel }}</span>
      </div>
      <gl-dropdown-divider />
    </template>
    <template v-else-if="dropdownItems.length">
      <gl-dropdown-item
        v-for="item in dropdownItems"
        :key="item"
        role="milestone option"
        @click="onMilestoneClicked(item)"
      >
        <span :class="{ 'pl-4': true, 'selected-item': isSelectedMilestone(item) }">
          {{ item }}
        </span>
      </gl-dropdown-item>
      <gl-dropdown-divider />
    </template>

    <gl-dropdown-item v-for="(item, idx) in extraLinks" :key="idx" :href="item.url">
      <span class="pl-4">{{ item.text }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
