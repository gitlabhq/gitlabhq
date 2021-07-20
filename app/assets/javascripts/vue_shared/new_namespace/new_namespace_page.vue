<script>
import { GlBreadcrumb, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';

import LegacyContainer from './components/legacy_container.vue';
import WelcomePage from './components/welcome.vue';

export default {
  components: {
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
    initialBreadcrumb: {
      type: String,
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

    details() {
      return this.activePanel.details || this.activePanel.description;
    },

    hasTextDetails() {
      return typeof this.details === 'string';
    },

    breadcrumbs() {
      if (!this.activePanel) {
        return null;
      }

      return [
        { text: this.initialBreadcrumb, href: '#' },
        { text: this.activePanel.title, href: `#${this.activePanel.name}` },
      ];
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
      window.location = e.target.href;
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
  <welcome-page v-if="!activePanelName" :panels="panels" :title="title">
    <template #footer>
      <slot name="welcome-footer"> </slot>
    </template>
  </welcome-page>
  <div v-else class="row">
    <div class="col-lg-3">
      <div v-safe-html="activePanel.illustration" class="gl-text-white"></div>
      <h4>{{ activePanel.title }}</h4>

      <p v-if="hasTextDetails">{{ details }}</p>
      <component :is="details" v-else />

      <slot name="extra-description"></slot>
    </div>
    <div class="col-lg-9">
      <gl-breadcrumb v-if="breadcrumbs" :items="breadcrumbs">
        <template #separator>
          <gl-icon name="chevron-right" :size="8" />
        </template>
      </gl-breadcrumb>
      <legacy-container :key="activePanel.name" :selector="activePanel.selector" />
    </div>
  </div>
</template>
