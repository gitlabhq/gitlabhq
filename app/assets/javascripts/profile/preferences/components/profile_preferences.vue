<script>
import { GlButton } from '@gitlab/ui';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { INTEGRATION_VIEW_CONFIGS, i18n } from '../constants';
import IntegrationView from './integration_view.vue';

function updateClasses(bodyClasses = '', applicationTheme, layout) {
  // Remove documentElement class for any previous theme, re-add current one
  document.documentElement.classList.remove(...bodyClasses.split(' '));
  document.documentElement.classList.add(applicationTheme);

  // Toggle container-fluid class
  if (layout === 'fluid') {
    document
      .querySelector('.content-wrapper .container-fluid')
      .classList.remove('container-limited');
  } else {
    document.querySelector('.content-wrapper .container-fluid').classList.add('container-limited');
  }
}

export default {
  name: 'ProfilePreferences',
  components: {
    IntegrationView,
    GlButton,
  },
  inject: {
    integrationViews: {
      default: [],
    },
    colorModes: {
      default: [],
    },
    themes: {
      default: [],
    },
    userFields: {
      default: {},
    },
    formEl: 'formEl',
    profilePreferencesPath: 'profilePreferencesPath',
    bodyClasses: 'bodyClasses',
  },
  integrationViewConfigs: INTEGRATION_VIEW_CONFIGS,
  i18n,
  data() {
    return {
      isSubmitEnabled: true,
      darkModeOnCreate: null,
      schemeOnCreate: null,
    };
  },
  created() {
    this.formEl.addEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.addEventListener('ajax:success', this.handleSuccess);
    this.formEl.addEventListener('ajax:error', this.handleError);
    this.darkModeOnCreate = this.darkModeSelected();
    this.schemeOnCreate = this.getSelectedScheme();
  },
  beforeDestroy() {
    this.formEl.removeEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.removeEventListener('ajax:success', this.handleSuccess);
    this.formEl.removeEventListener('ajax:error', this.handleError);
  },
  methods: {
    darkModeSelected() {
      const mode = this.getSelectedColorMode();
      return mode ? mode.css_class === 'gl-dark' : null;
    },
    getSelectedColorMode() {
      const modeId = new FormData(this.formEl).get('user[color_mode_id]');
      const mode = this.colorModes.find((item) => item.id === Number(modeId));
      return mode ?? null;
    },
    getSelectedTheme() {
      const themeId = new FormData(this.formEl).get('user[theme_id]');
      const theme = this.themes.find((item) => item.id === Number(themeId));
      return theme ?? null;
    },
    getSelectedScheme() {
      return new FormData(this.formEl).get('user[color_scheme_id]');
    },
    handleLoading() {
      this.isSubmitEnabled = false;
    },
    handleSuccess(customEvent) {
      // Reload the page if the theme has changed from light to dark mode or vice versa
      // or if color scheme has changed to correctly load all required styles.
      if (
        this.darkModeOnCreate !== this.darkModeSelected() ||
        this.schemeOnCreate !== this.getSelectedScheme()
      ) {
        window.location.reload();
        return;
      }
      updateClasses(this.bodyClasses, this.getSelectedTheme().css_class, this.selectedLayout);
      const message = customEvent?.detail?.[0]?.message || this.$options.i18n.defaultSuccess || '';
      this.$toast.show(message);
      this.isSubmitEnabled = true;
    },
    handleError(customEvent) {
      const { message = this.$options.i18n.defaultError, variant = VARIANT_DANGER } =
        customEvent?.detail?.[0] || {};
      createAlert({ message, variant });
      this.isSubmitEnabled = true;
    },
  },
};
</script>

<template>
  <div class="gl-display-contents js-preferences-form">
    <div
      v-if="integrationViews.length"
      class="settings-section gl-border-t gl-pt-6! js-search-settings-section"
    >
      <div class="settings-sticky-header">
        <div class="settings-sticky-header-inner">
          <h4 class="gl-my-0" data-testid="profile-preferences-integrations-heading">
            {{ $options.i18n.integrations }}
          </h4>
        </div>
      </div>
      <p class="gl-text-secondary">
        {{ $options.i18n.integrationsDescription }}
      </p>
      <div>
        <integration-view
          v-for="view in integrationViews"
          :key="view.name"
          :help-link="view.help_link"
          :message="view.message"
          :message-url="view.message_url"
          :config="$options.integrationViewConfigs[view.name]"
        />
      </div>
    </div>
    <div class="settings-sticky-footer js-hide-when-nothing-matches-search">
      <gl-button
        category="primary"
        variant="confirm"
        name="commit"
        type="submit"
        :disabled="!isSubmitEnabled"
        :value="$options.i18n.saveChanges"
      >
        {{ $options.i18n.saveChanges }}
      </gl-button>
    </div>
  </div>
</template>
