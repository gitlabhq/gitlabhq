<script>
import { isEqual } from 'lodash-es';
import { GlButton, GlToastMixin } from '@gitlab/ui';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { i18n } from '../constants';

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
    GlButton,
  },
  mixins: [GlToastMixin],
  inject: {
    colorModes: {
      default: [],
    },
    themes: {
      default: [],
    },
    formEl: 'formEl',
    bodyClasses: 'bodyClasses',
  },
  i18n,
  data() {
    return {
      isSubmitEnabled: true,
      colorModeOnCreate: null,
      schemeOnCreate: null,
      darkSchemeOnCreate: null,
    };
  },
  created() {
    this.formEl.addEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.addEventListener('ajax:success', this.handleSuccess);
    this.formEl.addEventListener('ajax:error', this.handleError);
    this.colorModeOnCreate = this.getSelectedColorMode();
    this.schemeOnCreate = this.getSelectedScheme();
    this.darkSchemeOnCreate = this.getSelectedDarkScheme();
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
    getSelectedDarkScheme() {
      return new FormData(this.formEl).get('user[dark_color_scheme_id]');
    },
    getSelectedLayout() {
      return new FormData(this.formEl).get('user[layout]');
    },
    handleLoading() {
      this.isSubmitEnabled = false;
    },
    handleSuccess(customEvent) {
      // Reload the page if the theme has changed from light to dark mode or vice versa
      // or if color scheme has changed to correctly load all required styles.
      if (
        !isEqual(this.colorModeOnCreate, this.getSelectedColorMode()) ||
        !isEqual(this.schemeOnCreate, this.getSelectedScheme()) ||
        !isEqual(this.darkSchemeOnCreate, this.getSelectedDarkScheme())
      ) {
        window.location.reload();
        return;
      }
      updateClasses(this.bodyClasses, this.getSelectedTheme().css_class, this.getSelectedLayout());
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
  <div class="settings-sticky-footer js-hide-when-nothing-matches-search">
    <gl-button
      category="primary"
      variant="confirm"
      name="commit"
      type="submit"
      class="js-no-auto-disable"
      :disabled="!isSubmitEnabled"
      :value="$options.i18n.saveChanges"
    >
      {{ $options.i18n.saveChanges }}
    </gl-button>
  </div>
</template>
