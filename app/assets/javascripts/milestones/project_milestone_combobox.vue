<script>
import {
  GlNewDropdown,
  GlNewDropdownDivider,
  GlNewDropdownHeader,
  GlNewDropdownItem,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlIcon,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Api from '~/api';
import createFlash from '~/flash';
import { intersection, debounce } from 'lodash';

export default {
  components: {
    GlNewDropdown,
    GlNewDropdownDivider,
    GlNewDropdownHeader,
    GlNewDropdownItem,
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
  mounted() {
    this.fetchMilestones();
  },
  methods: {
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
    searchMilestones: debounce(function searchMilestones() {
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
    }, 100),
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
  <gl-new-dropdown>
    <template slot="button-content">
      <span ref="buttonText" class="flex-grow-1 ml-1 text-muted">{{
        selectedMilestonesLabel
      }}</span>
      <gl-icon name="chevron-down" />
    </template>

    <gl-new-dropdown-header>
      <span class="text-center d-block">{{ $options.translations.selectMilestone }}</span>
    </gl-new-dropdown-header>

    <gl-new-dropdown-divider />

    <gl-search-box-by-type
      v-model.trim="searchQuery"
      class="m-2"
      :placeholder="this.$options.translations.searchMilestones"
      @input="searchMilestones"
    />

    <gl-new-dropdown-item @click="onMilestoneClicked(null)">
      <span :class="{ 'pl-4': true, 'selected-item': selectedMilestones.length === 0 }">
        {{ $options.translations.noMilestone }}
      </span>
    </gl-new-dropdown-item>

    <gl-new-dropdown-divider />

    <template v-if="isLoading">
      <gl-loading-icon />
      <gl-new-dropdown-divider />
    </template>
    <template v-else-if="noResults">
      <div class="dropdown-item-space">
        <span ref="noResults" class="pl-4">{{ $options.translations.noResultsLabel }}</span>
      </div>
      <gl-new-dropdown-divider />
    </template>
    <template v-else-if="dropdownItems.length">
      <gl-new-dropdown-item
        v-for="item in dropdownItems"
        :key="item"
        role="milestone option"
        @click="onMilestoneClicked(item)"
      >
        <span :class="{ 'pl-4': true, 'selected-item': isSelectedMilestone(item) }">
          {{ item }}
        </span>
      </gl-new-dropdown-item>
      <gl-new-dropdown-divider />
    </template>

    <gl-new-dropdown-item v-for="(item, idx) in extraLinks" :key="idx" :href="item.url">
      <span class="pl-4">{{ item.text }}</span>
    </gl-new-dropdown-item>
  </gl-new-dropdown>
</template>
