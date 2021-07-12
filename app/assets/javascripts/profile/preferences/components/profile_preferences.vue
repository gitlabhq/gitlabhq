<script>
import { GlButton } from '@gitlab/ui';
import createFlash, { FLASH_TYPES } from '~/flash';
import { INTEGRATION_VIEW_CONFIGS, i18n } from '../constants';
import IntegrationView from './integration_view.vue';

function updateClasses(bodyClasses = '', applicationTheme, layout) {
  // Remove body class for any previous theme, re-add current one
  document.body.classList.remove(...bodyClasses.split(' '));
  document.body.classList.add(applicationTheme);

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
      darkModeOnSubmit: null,
    };
  },
  computed: {
    applicationThemes() {
      return this.themes.reduce((themes, theme) => {
        const { id, ...rest } = theme;
        return { ...themes, [id]: rest };
      }, {});
    },
  },
  created() {
    this.formEl.addEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.addEventListener('ajax:success', this.handleSuccess);
    this.formEl.addEventListener('ajax:error', this.handleError);
    this.darkModeOnCreate = this.darkModeSelected();
  },
  beforeDestroy() {
    this.formEl.removeEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.removeEventListener('ajax:success', this.handleSuccess);
    this.formEl.removeEventListener('ajax:error', this.handleError);
  },
  methods: {
    darkModeSelected() {
      const theme = this.getSelectedTheme();
      return theme ? theme.css_class === 'gl-dark' : null;
    },
    getSelectedTheme() {
      const themeId = new FormData(this.formEl).get('user[theme_id]');
      return this.applicationThemes[themeId] ?? null;
    },
    handleLoading() {
      this.isSubmitEnabled = false;
      this.darkModeOnSubmit = this.darkModeSelected();
    },
    handleSuccess(customEvent) {
      // Reload the page if the theme has changed from light to dark mode or vice versa
      // to correctly load all required styles.
      const modeChanged = this.darkModeOnCreate ? !this.darkModeOnSubmit : this.darkModeOnSubmit;
      if (modeChanged) {
        window.location.reload();
        return;
      }
      updateClasses(this.bodyClasses, this.getSelectedTheme().css_class, this.selectedLayout);
      const { message = this.$options.i18n.defaultSuccess, type = FLASH_TYPES.NOTICE } =
        customEvent?.detail?.[0] || {};
      createFlash({ message, type });
      this.isSubmitEnabled = true;
    },
    handleError(customEvent) {
      const { message = this.$options.i18n.defaultError, type = FLASH_TYPES.ALERT } =
        customEvent?.detail?.[0] || {};
      createFlash({ message, type });
      this.isSubmitEnabled = true;
    },
  },
};
</script>

<template>
  <div class="row gl-mt-3 js-preferences-form">
    <div v-if="integrationViews.length" class="col-sm-12">
      <hr data-testid="profile-preferences-integrations-rule" />
    </div>
    <div v-if="integrationViews.length" class="col-lg-4 profile-settings-sidebar">
      <h4 class="gl-mt-0" data-testid="profile-preferences-integrations-heading">
        {{ $options.i18n.integrations }}
      </h4>
      <p>
        {{ $options.i18n.integrationsDescription }}
      </p>
    </div>
    <div v-if="integrationViews.length" class="col-lg-8">
      <integration-view
        v-for="view in integrationViews"
        :key="view.name"
        :help-link="view.help_link"
        :message="view.message"
        :message-url="view.message_url"
        :config="$options.integrationViewConfigs[view.name]"
      />
    </div>
    <div class="col-lg-4 profile-settings-sidebar"></div>
    <div class="col-lg-8">
      <div class="form-group">
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
  </div>
</template>
