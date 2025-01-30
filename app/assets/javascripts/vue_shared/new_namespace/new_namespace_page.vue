<script>
import { GlBreadcrumb, GlIcon, GlAlert } from '@gitlab/ui';
import NewTopLevelGroupAlert from '~/groups/components/new_top_level_group_alert.vue';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { sidebarState, JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';
import { s__ } from '~/locale';
import LegacyContainer from './components/legacy_container.vue';
import WelcomePage from './components/welcome.vue';

export default {
  JS_TOGGLE_EXPAND_CLASS,
  components: {
    NewTopLevelGroupAlert,
    GlBreadcrumb,
    GlIcon,
    GlAlert,
    WelcomePage,
    LegacyContainer,
    SuperSidebarToggle,
  },

  inject: ['identityVerificationRequired', 'identityVerificationPath'],

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
    isSaas: {
      type: Boolean,
      required: false,
      default: false,
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
      return this.isSaas && this.activePanel.detailProps?.parentGroupName === '';
    },

    showSuperSidebarToggle() {
      return sidebarState.isCollapsed;
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

  i18n: {
    restrictedAlert: {
      title: s__(
        'IdentityVerification|Before you can create additional groups, we need to verify your account.',
      ),
      description: s__(
        `IdentityVerification|We won't ask you for this information again. It will never be used for marketing purposes.`,
      ),
      buttonText: s__('IdentityVerification|Verify my account'),
    },
  },
};
</script>

<template>
  <div>
    <div class="top-bar-fixed container-fluid" data-testid="top-bar">
      <div
        class="top-bar-container gl-flex gl-items-center gl-border-b-1 gl-border-b-default gl-border-b-solid"
      >
        <super-sidebar-toggle
          v-if="showSuperSidebarToggle"
          class="gl-mr-2"
          :class="$options.JS_TOGGLE_EXPAND_CLASS"
        />
        <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" class="gl-grow" />
      </div>
    </div>

    <template v-if="activePanel">
      <div data-testid="active-panel-template" class="gl-flex gl-items-center gl-py-5">
        <div class="col-auto">
          <img aria-hidden="true" :src="activePanel.imageSrc" :alt="activePanel.title" />
        </div>
        <div class="col">
          <h1 class="gl-heading-2-fixed gl-my-3">{{ activePanel.title }}</h1>

          <p v-if="hasTextDetails">{{ details }}</p>
          <component :is="details" v-else v-bind="detailProps" />
        </div>

        <slot name="extra-description"></slot>
      </div>

      <gl-alert
        v-if="identityVerificationRequired"
        :title="$options.i18n.restrictedAlert.title"
        :dismissible="false"
        :primary-button-text="$options.i18n.restrictedAlert.buttonText"
        :primary-button-link="identityVerificationPath"
        variant="danger"
      >
        {{ $options.i18n.restrictedAlert.description }}
      </gl-alert>

      <div v-else>
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
