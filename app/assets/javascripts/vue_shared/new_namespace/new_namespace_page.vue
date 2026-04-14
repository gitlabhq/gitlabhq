<script>
import { MountingPortal } from 'portal-vue';
import { GlBreadcrumb, GlIcon, GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import LegacyContainer from './components/legacy_container.vue';
import WelcomePage from './components/welcome.vue';

export default {
  components: {
    PageHeading,
    GlBreadcrumb,
    GlIcon,
    GlAlert,
    GlSprintf,
    GlLink,
    WelcomePage,
    LegacyContainer,
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
    message: s__(
      'ProjectTemplates|Learn how to %{linkStart}contribute to the built-in templates%{linkEnd}.',
    ),
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
    <mounting-portal mount-to="#js-vue-page-breadcrumbs-wrapper" name="breadcrumbs" append>
      <gl-breadcrumb :items="breadcrumbs" data-testid="breadcrumb-links" class="gl-grow" />
    </mounting-portal>

    <template v-if="activePanel">
      <page-heading :heading="activePanel.title" data-testid="active-panel-template">
        <template #description>
          <template v-if="hasTextDetails">{{ details }}</template>
          <component :is="details" v-else v-bind="detailProps" />
          <gl-sprintf v-if="activePanel.key === 'template'" :message="$options.i18n.message">
            <template #link="{ content }">
              <gl-link
                href="https://gitlab.com/gitlab-org/project-templates/contributing"
                target="_blank"
                rel="noopener noreferrer"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
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
