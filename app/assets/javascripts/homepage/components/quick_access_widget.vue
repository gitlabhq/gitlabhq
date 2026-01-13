<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';
import RecentlyViewedItems from './recently_viewed_items.vue';
import ProjectsList from './projects_list.vue';
import BaseWidget from './base_widget.vue';

const VIEW_RECENTLY_VIEWED = 'recently-viewed';
const VIEW_FRECENT_PROJECTS = 'frecent-projects';
const VALID_VIEWS = [VIEW_RECENTLY_VIEWED, VIEW_FRECENT_PROJECTS];
const STORAGE_KEY_ACTIVE_VIEW = 'homepage_quick_access_active_view';

export default {
  name: 'QuickAccessWidget',
  components: {
    GlButtonGroup,
    GlButton,
    RecentlyViewedItems,
    ProjectsList,
    BaseWidget,
  },
  data() {
    let savedActiveView = VIEW_RECENTLY_VIEWED;

    if (AccessorUtilities.canUseLocalStorage()) {
      const storedView = localStorage.getItem(STORAGE_KEY_ACTIVE_VIEW);
      if (storedView && VALID_VIEWS.includes(storedView)) {
        savedActiveView = storedView;
      }
    }

    return {
      activeView: savedActiveView,
    };
  },
  computed: {
    isRecentlyViewedActive() {
      return this.activeView === VIEW_RECENTLY_VIEWED;
    },
    isFrecentProjectsActive() {
      return this.activeView === VIEW_FRECENT_PROJECTS;
    },
  },
  methods: {
    setActiveView(view) {
      this.activeView = view;
      if (AccessorUtilities.canUseLocalStorage()) {
        localStorage.setItem(STORAGE_KEY_ACTIVE_VIEW, view);
      }
    },
  },
  VIEW_RECENTLY_VIEWED,
  VIEW_FRECENT_PROJECTS,
};
</script>

<template>
  <base-widget>
    <h2 class="gl-heading-4 gl-mb-4">{{ __('Quick access') }}</h2>
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
    <projects-list v-else />
  </base-widget>
</template>
