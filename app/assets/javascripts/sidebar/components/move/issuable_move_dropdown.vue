<script>
import {
  GlIcon,
  GlButton,
  GlCollapsibleListbox,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlIcon,
    GlButton,
    GlCollapsibleListbox,
  },
  directives: {
    GlTooltip,
  },
  props: {
    projectsFetchPath: {
      type: String,
      required: true,
    },
    dropdownButtonTitle: {
      type: String,
      required: true,
    },
    dropdownHeaderTitle: {
      type: String,
      required: true,
    },
    moveInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      projects: [],
      projectsList: [],
      selectedProjects: [],
      noResultsText: '',
      isSearching: false,
    };
  },
  mounted() {
    this.fetchProjects = debounce(this.fetchProjects, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    triggerSearch() {
      this.$refs.dropdown.search();
    },
    async fetchProjects(search = '') {
      this.isSearching = true;

      try {
        const { data } = await axios.get(this.projectsFetchPath, {
          params: {
            search,
          },
        });
        this.projects = data;
        this.projectsList = data.map((item) => ({
          value: item.id,
          text: item.name_with_namespace,
        }));

        if (!this.projectsList.length) {
          this.noResultsText = __('No matching results');
        }
      } catch (e) {
        this.noResultsText = __('Failed to load projects');
      } finally {
        this.isSearching = false;
      }
    },
    handleProjectSelect(items) {
      // hack: simulate a single select to prevent the dropdown from closing
      // todo: switch back to single select when https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2363 is fixed
      this.selectedProjects = [items[items.length - 1]];
    },
    handleMoveClick() {
      this.$refs.dropdown.close();
      this.$emit(
        'move-issuable',
        this.projects.find((item) => item.id === this.selectedProjects[0]),
      );
    },
    handleDropdownHide() {
      this.$emit('dropdown-close');
    },
  },
};
</script>

<template>
  <div class="js-issuable-move-block issuable-move-dropdown sidebar-move-issue-dropdown">
    <div
      v-gl-tooltip.left.viewport
      data-testid="move-collapsed"
      :title="dropdownButtonTitle"
      class="sidebar-collapsed-icon"
      @click="$emit('toggle-collapse')"
    >
      <gl-icon name="arrow-right" />
    </div>
    <gl-collapsible-listbox
      ref="dropdown"
      v-model="selectedProjects"
      :items="projectsList"
      :block="true"
      :multiple="true"
      :searchable="true"
      :searching="isSearching"
      :search-placeholder="__('Search project')"
      :no-results-text="noResultsText"
      :header-text="dropdownButtonTitle"
      @hidden="handleDropdownHide"
      @shown="triggerSearch"
      @search="fetchProjects"
      @select="handleProjectSelect"
    >
      <template #toggle>
        <gl-button
          :loading="moveInProgress"
          size="medium"
          class="js-sidebar-dropdown-toggle hide-collapsed gl-w-full"
          data-testid="dropdown-button"
          :disabled="moveInProgress || disabled"
          >{{ dropdownButtonTitle }}</gl-button
        >
      </template>
      <template #footer>
        <div data-testid="footer" class="gl-p-3">
          <gl-button
            category="primary"
            variant="confirm"
            :disabled="!Boolean(selectedProjects.length)"
            class="gl-w-full"
            data-testid="dropdown-move-button"
            @click="handleMoveClick"
            >{{ __('Move') }}</gl-button
          >
        </div>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
