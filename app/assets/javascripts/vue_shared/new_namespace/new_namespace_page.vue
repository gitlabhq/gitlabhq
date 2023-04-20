<script>
import { GlBreadcrumb, GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NewTopLevelGroupAlert from '~/groups/components/new_top_level_group_alert.vue';

import LegacyContainer from './components/legacy_container.vue';
import WelcomePage from './components/welcome.vue';

export default {
  components: {
    NewTopLevelGroupAlert,
    GlBreadcrumb,
    GlIcon,
    WelcomePage,
    LegacyContainer,
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
  <div v-if="!activePanelName" class="gl-mt-4">
    <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" />
    <welcome-page :panels="panels" :title="title">
      <template #footer>
        <slot name="welcome-footer"> </slot>
      </template>
    </welcome-page>
  </div>
  <div v-else class="gl-pt-4">
    <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" />
    <div
      class="gl-display-flex gl-align-items-center gl-mt-4 gl-py-5 gl-border-t-1 gl-border-t-gray-100 gl-border-t-solid"
    >
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
  </div>
</template>
