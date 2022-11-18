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
    CreditCardVerification: () =>
      import('ee_component/namespaces/verification/components/credit_card_verification.vue'),
  },
  directives: {
    SafeHtml,
  },
  inject: {
    verificationRequired: {
      default: false,
    },
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
      verificationCompleted: false,
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

    shouldVerify() {
      return this.verificationRequired && !this.verificationCompleted;
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
    onVerified() {
      this.verificationCompleted = true;
    },
  },
};
</script>

<template>
  <credit-card-verification v-if="shouldVerify" @verified="onVerified" />
  <welcome-page v-else-if="!activePanelName" :panels="panels" :title="title">
    <template #footer>
      <slot name="welcome-footer"> </slot>
    </template>
  </welcome-page>
  <div v-else class="row">
    <div class="col-lg-3">
      <div v-safe-html="activePanel.illustration" class="gl-text-white"></div>
      <h4>{{ activePanel.title }}</h4>

      <p v-if="hasTextDetails">{{ details }}</p>
      <component :is="details" v-else v-bind="activePanel.detailProps || {}" />

      <slot name="extra-description"></slot>
    </div>
    <div class="col-lg-9">
      <new-top-level-group-alert v-if="showNewTopLevelGroupAlert" />
      <gl-breadcrumb v-if="breadcrumbs" :items="breadcrumbs" />
      <legacy-container :key="activePanel.name" :selector="activePanel.selector" />
    </div>
  </div>
</template>
