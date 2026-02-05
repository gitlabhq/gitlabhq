<script>
import { GlButtonGroup, GlButton, GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';
import { __ } from '~/locale';
import { PROJECT_SOURCE_LABELS, DEFAULT_PROJECT_SOURCES } from '~/homepage/constants';
import RecentlyViewedItems from './recently_viewed_items.vue';
import ProjectsList from './projects_list.vue';
import BaseWidget from './base_widget.vue';

const VIEW_RECENTLY_VIEWED = 'recently-viewed';
const VIEW_FRECENT_PROJECTS = 'frecent-projects';
const VALID_VIEWS = [VIEW_RECENTLY_VIEWED, VIEW_FRECENT_PROJECTS];
const STORAGE_KEY_ACTIVE_VIEW = 'homepage_active_view';
const STORAGE_KEY_PROJECT_SOURCES = 'homepage_project_sources';

export default {
  name: 'QuickAccessWidget',
  components: {
    GlButtonGroup,
    GlButton,
    GlCollapsibleListbox,
    RecentlyViewedItems,
    ProjectsList,
    BaseWidget,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    displayOptions: __('Display options'),
  },
  data() {
    let savedActiveView = VIEW_RECENTLY_VIEWED;
    let savedProjectSources = DEFAULT_PROJECT_SOURCES;

    if (AccessorUtilities.canUseLocalStorage()) {
      const storedView = localStorage.getItem(STORAGE_KEY_ACTIVE_VIEW);
      if (storedView && VALID_VIEWS.includes(storedView)) {
        savedActiveView = storedView;
      }

      const storedSources = localStorage.getItem(STORAGE_KEY_PROJECT_SOURCES);
      if (storedSources) {
        try {
          savedProjectSources = JSON.parse(storedSources);
        } catch {
          // Use default if parsing fails
        }
      }
    }

    return {
      activeView: savedActiveView,
      selectedProjectSources: savedProjectSources,
      isListboxOpen: false,
    };
  },
  computed: {
    isRecentlyViewedActive() {
      return this.activeView === VIEW_RECENTLY_VIEWED;
    },
    isFrecentProjectsActive() {
      return this.activeView === VIEW_FRECENT_PROJECTS;
    },
    projectSourceOptions() {
      return Object.entries(PROJECT_SOURCE_LABELS).map(([value, text]) => ({
        value,
        text,
      }));
    },
  },
  methods: {
    saveToLocalStorage(key, value) {
      if (AccessorUtilities.canUseLocalStorage()) {
        localStorage.setItem(key, typeof value === 'string' ? value : JSON.stringify(value));
      }
    },
    setActiveView(view) {
      this.activeView = view;
      this.saveToLocalStorage(STORAGE_KEY_ACTIVE_VIEW, view);
    },
    updateProjectSources(sources) {
      this.selectedProjectSources = sources.length > 0 ? sources : DEFAULT_PROJECT_SOURCES;
      this.saveToLocalStorage(STORAGE_KEY_PROJECT_SOURCES, this.selectedProjectSources);
    },
  },
  VIEW_RECENTLY_VIEWED,
  VIEW_FRECENT_PROJECTS,
};
</script>

<template>
  <base-widget>
    <div class="gl-mb-4 gl-flex gl-h-[1.25rem] gl-items-center gl-justify-between">
      <h2 class="gl-heading-4 gl-mb-0">{{ __('Quick access') }}</h2>
      <gl-collapsible-listbox
        v-if="isFrecentProjectsActive"
        v-gl-tooltip="!isListboxOpen ? $options.i18n.displayOptions : ''"
        :items="projectSourceOptions"
        :selected="selectedProjectSources"
        multiple
        icon="preferences"
        no-caret
        :toggle-text="$options.i18n.displayOptions"
        text-sr-only
        category="tertiary"
        :header-text="$options.i18n.displayOptions"
        @select="updateProjectSources"
        @shown="isListboxOpen = true"
        @hidden="isListboxOpen = false"
      />
    </div>

    <gl-button-group role="tablist" class="gl-mb-3 gl-w-full">
      <gl-button
        role="tab"
        :aria-selected="isRecentlyViewedActive"
        :selected="isRecentlyViewedActive"
        class="gl-w-full gl-justify-center"
        @click="setActiveView($options.VIEW_RECENTLY_VIEWED)"
      >
        {{ __('Recently viewed') }}
      </gl-button>
      <gl-button
        role="tab"
        :aria-selected="isFrecentProjectsActive"
        :selected="isFrecentProjectsActive"
        class="gl-w-full gl-justify-center"
        @click="setActiveView($options.VIEW_FRECENT_PROJECTS)"
      >
        {{ __('Projects') }}
      </gl-button>
    </gl-button-group>

    <recently-viewed-items v-if="isRecentlyViewedActive" />
    <projects-list v-else :selected-sources="selectedProjectSources" />
  </base-widget>
</template>
