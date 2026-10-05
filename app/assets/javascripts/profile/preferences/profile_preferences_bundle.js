import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { initListboxInputs } from '~/vue_shared/components/listbox_input/init_listbox_inputs';
import ProfilePreferences from './components/profile_preferences.vue';
import ProfilePreferencesIntegrations from './components/integrations.vue';
import ColorModeSelector from './components/color_mode_selector.vue';

function initColorModeSelector() {
  const el = document.querySelector('#js-color-mode-selector');

  if (!el) return null;

  const colorModes = JSON.parse(el.dataset.colorModes);
  const initialColorModeId = Number(el.dataset.initialColorModeId);

  return initVueApp({
    el,
    name: 'ColorModeSelectorRoot',
    component: ColorModeSelector,
    props: {
      colorModes,
      initialColorModeId,
    },
  });
}

function initTextEditorPreference() {
  const defaultTextEditorEnabledCheckbox = document.querySelector(
    'input[type="checkbox"][name="user[default_text_editor_enabled]"]',
  );
  const textEditorRadioButtons = [
    ...document.querySelectorAll('input[type="radio"][name="user[text_editor]"]'),
  ];
  const notSetHiddenField = document.querySelector(
    'input[type="hidden"][name="user[text_editor]"]',
  );

  const handleCheckboxChange = () => {
    if (defaultTextEditorEnabledCheckbox.checked) {
      textEditorRadioButtons.forEach((radio) => radio.removeAttribute('disabled'));
      notSetHiddenField.setAttribute('disabled', 'disabled');
    } else {
      textEditorRadioButtons.forEach((radio) => radio.setAttribute('disabled', 'disabled'));
      notSetHiddenField.removeAttribute('disabled');
    }

    // if none of the radio buttons are checked, check the first one
    if (!textEditorRadioButtons.some((radio) => radio.checked)) {
      textEditorRadioButtons[0].checked = true;
    }
  };

  defaultTextEditorEnabledCheckbox.addEventListener('change', handleCheckboxChange);
  handleCheckboxChange();
}

function initOrbitSubsettings() {
  const mainCheckbox = document.querySelector('input[type="checkbox"][name="user[orbit_enabled]"]');
  const subsettingsContainer = document.querySelector('[data-testid="orbit-subsettings"]');

  if (!mainCheckbox || !subsettingsContainer) return;

  const subCheckboxes = [
    ...subsettingsContainer.querySelectorAll('input[type="checkbox"][name^="user[orbit_"]'),
  ];

  const handleMainChange = () => {
    if (mainCheckbox.checked) {
      subsettingsContainer.classList.remove('gl-hidden');
      for (const checkbox of subCheckboxes) {
        checkbox.checked = true;
      }
    } else {
      subsettingsContainer.classList.add('gl-hidden');
    }
  };

  mainCheckbox.addEventListener('change', handleMainChange);
}

function initIntegrations() {
  const el = document.querySelector('#js-profile-preferences-integrations');

  if (!el) return null;

  const { integrationViews, userFields, extensionsMarketplaceUrl } = el.dataset;

  return initVueApp({
    el,
    name: 'ProfilePreferencesIntegrationsRoot',
    component: ProfilePreferencesIntegrations,
    provide: {
      integrationViews: JSON.parse(integrationViews),
      userFields: JSON.parse(userFields),
      extensionsMarketplaceUrl,
    },
  });
}

export default () => {
  initListboxInputs();
  initTextEditorPreference();
  initOrbitSubsettings();
  initColorModeSelector();
  initIntegrations();

  const el = document.querySelector('#js-profile-preferences-app');
  const formEl = document.querySelector('#profile-preferences-form');
  const { colorModes, themes, bodyClasses } = el.dataset;

  return initVueApp({
    el,
    name: 'ProfilePreferencesApp',
    component: ProfilePreferences,
    provide: {
      formEl,
      colorModes: JSON.parse(colorModes),
      themes: JSON.parse(themes),
      bodyClasses,
    },
  });
};
