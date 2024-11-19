<script>
import { GlButton } from '@gitlab/ui';
import { createAlert, VARIANT_DANGER } from '~/alert';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import { INTEGRATION_VIEW_CONFIGS, i18n, INTEGRATION_EXTENSIONS_MARKETPLACE } from '../constants';
import IntegrationView from './integration_view.vue';
import ExtensionsMarketplaceWarning from './extensions_marketplace_warning.vue';

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
    ExtensionsMarketplaceWarning,
    SettingsSection,
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
  INTEGRATION_EXTENSIONS_MARKETPLACE,
  data() {
    const integrationValues = this.integrationViews.reduce((acc, { name }) => {
      const { formName } = INTEGRATION_VIEW_CONFIGS[name];

      acc[name] = Boolean(this.userFields[formName]);

      return acc;
    }, {});

    return {
      isSubmitEnabled: true,
      colorModeOnCreate: null,
      schemeOnCreate: null,
      integrationValues,
    };
  },
  computed: {
    extensionsMarketplaceView() {
      return this.integrationViews.find(({ name }) => name === INTEGRATION_EXTENSIONS_MARKETPLACE);
    },
  },
  created() {
    this.formEl.addEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.addEventListener('ajax:success', this.handleSuccess);
    this.formEl.addEventListener('ajax:error', this.handleError);
    this.colorModeOnCreate = this.getSelectedColorMode();
    this.schemeOnCreate = this.getSelectedScheme();
  },
  beforeDestroy() {
    this.formEl.removeEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.removeEventListener('ajax:success', this.handleSuccess);
    this.formEl.removeEventListener('ajax:error', this.handleError);
  },
  methods: {
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
        this.colorModeOnCreate !== this.getSelectedColorMode() ||
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
  <div class="settings-section">
    <settings-section v-if="integrationViews.length" id="integrations" class="js-preferences-form">
      <template #heading>
        {{ $options.i18n.integrations }}
      </template>

      <template #description>
        {{ $options.i18n.integrationsDescription }}
      </template>

      <div>
        <integration-view
          v-for="view in integrationViews"
          :key="view.name"
          v-model="integrationValues[view.name]"
          :help-link="view.help_link"
          :message="view.message"
          :message-url="view.message_url"
          :config="$options.integrationViewConfigs[view.name]"
          :title="view.title"
        />
      </div>
    </settings-section>

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
    <extensions-marketplace-warning
      v-if="extensionsMarketplaceView"
      v-model="integrationValues[$options.INTEGRATION_EXTENSIONS_MARKETPLACE]"
      :help-url="extensionsMarketplaceView.help_link"
    />
  </div>
</template>
