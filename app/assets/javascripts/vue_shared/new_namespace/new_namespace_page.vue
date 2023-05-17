<script>
import { GlBreadcrumb, GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NewTopLevelGroupAlert from '~/groups/components/new_top_level_group_alert.vue';

import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { sidebarState, JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';
import LegacyContainer from './components/legacy_container.vue';
import WelcomePage from './components/welcome.vue';

export default {
  JS_TOGGLE_EXPAND_CLASS,
  components: {
    NewTopLevelGroupAlert,
    GlBreadcrumb,
    GlIcon,
    WelcomePage,
    LegacyContainer,
    SuperSidebarToggle,
  },
  directives: {
    SafeHtml,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    initialBreadcrumbs: {
      type: Array,
      required: true,
    },
    panels: {
      type: Array,
      required: true,
    },
    jumpToLastPersistedPanel: {
      type: Boolean,
      required: false,
      default: false,
    },
    persistenceKey: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      activePanelName: null,
    };
  },

  computed: {
    activePanel() {
      return this.panels.find((p) => p.name === this.activePanelName);
    },

    detailProps() {
      return this.activePanel.detailProps || {};
    },

    details() {
      return this.activePanel.details || this.activePanel.description;
    },

    hasTextDetails() {
      return typeof this.details === 'string';
    },

    breadcrumbs() {
      return this.activePanel
        ? [
            ...this.initialBreadcrumbs,
            {
              text: this.activePanel.title,
              href: `#${this.activePanel.name}`,
            },
          ]
        : this.initialBreadcrumbs;
    },

    showNewTopLevelGroupAlert() {
      if (this.activePanel.detailProps === undefined) {
        return false;
      }

      return this.activePanel.detailProps.parentGroupName === '';
    },

    showSuperSidebarToggle() {
      return gon.use_new_navigation && sidebarState.isCollapsed;
    },
  },

  created() {
    this.handleLocationHashChange();

    if (this.jumpToLastPersistedPanel) {
      this.activePanelName = localStorage.getItem(this.persistenceKey) || this.panels[0].name;
    }

    window.addEventListener('hashchange', () => {
      this.handleLocationHashChange();
      this.$emit('panel-change');
    });

    this.$root.$on('clicked::link', (e) => {
      window.location = e.currentTarget.href;
    });
  },

  methods: {
    handleLocationHashChange() {
      this.activePanelName = window.location.hash.substring(1) || null;
      if (this.activePanelName) {
        localStorage.setItem(this.persistenceKey, this.activePanelName);
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="top-bar-container gl-display-flex gl-align-items-center gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid"
    >
      <super-sidebar-toggle
        v-if="showSuperSidebarToggle"
        class="gl-mr-2"
        :class="$options.JS_TOGGLE_EXPAND_CLASS"
      />
      <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" />
    </div>

    <template v-if="activePanel">
      <div class="gl-display-flex gl-align-items-center gl-py-5">
        <div v-safe-html="activePanel.illustration" class="gl-text-white col-auto"></div>
        <div class="col">
          <h4>{{ activePanel.title }}</h4>

          <p v-if="hasTextDetails">{{ details }}</p>
          <component :is="details" v-else v-bind="detailProps" />
        </div>

        <slot name="extra-description"></slot>
      </div>
      <div>
        <new-top-level-group-alert v-if="showNewTopLevelGroupAlert" />
        <legacy-container :key="activePanel.name" :selector="activePanel.selector" />
      </div>
    </template>

    <welcome-page v-else :panels="panels" :title="title">
      <template #footer>
        <slot name="welcome-footer"></slot>
      </template>
    </welcome-page>
  </div>
</template>
