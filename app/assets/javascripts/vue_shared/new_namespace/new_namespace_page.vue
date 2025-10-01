<script>
import { MountingPortal } from 'portal-vue';
import { GlBreadcrumb, GlIcon, GlAlert } from '@gitlab/ui';
import NewTopLevelGroupAlert from '~/groups/components/new_top_level_group_alert.vue';
import SuperSidebarToggle from '~/super_sidebar/components/super_sidebar_toggle.vue';
import { sidebarState, JS_TOGGLE_EXPAND_CLASS } from '~/super_sidebar/constants';
import { s__ } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import LegacyContainer from './components/legacy_container.vue';
import WelcomePage from './components/welcome.vue';

export default {
  JS_TOGGLE_EXPAND_CLASS,
  components: {
    PageHeading,
    NewTopLevelGroupAlert,
    GlBreadcrumb,
    GlIcon,
    GlAlert,
    WelcomePage,
    LegacyContainer,
    SuperSidebarToggle,
    MountingPortal,
  },

  inject: {
    identityVerificationRequired: { default: false },
    identityVerificationPath: { default: null },
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
    isUsingPaneledView() {
      return gon.features?.projectStudioEnabled;
    },
    wrapperComponentProps() {
      return this.isUsingPaneledView
        ? {
            is: MountingPortal,
            'mount-to': '.panel-header',
            name: 'breadcrumbs',
            append: true,
          }
        : {
            is: 'div',
          };
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
    <component :is="wrapperComponentProps.is" v-bind="wrapperComponentProps">
      <div
        class="top-bar-fixed container-fluid"
        :class="{ 'gl-border-b gl-top-0 gl-mx-0 gl-w-full': isUsingPaneledView }"
        data-testid="top-bar"
      >
        <div
          class="top-bar-container gl-flex gl-items-center gl-border-b-default gl-border-b-solid"
          :class="isUsingPaneledView ? 'gl-border-b-0' : 'gl-border-b-1'"
        >
          <super-sidebar-toggle
            v-if="showSuperSidebarToggle"
            class="gl-mr-2"
            :class="$options.JS_TOGGLE_EXPAND_CLASS"
          />
          <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" class="gl-grow" />
        </div>
      </div>
    </component>

    <template v-if="activePanel">
      <page-heading :heading="activePanel.title" data-testid="active-panel-template">
        <template #description>
          <template v-if="hasTextDetails">{{ details }}</template>
          <component :is="details" v-else v-bind="detailProps" />
          <slot name="extra-description"></slot>
        </template>
      </page-heading>

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
