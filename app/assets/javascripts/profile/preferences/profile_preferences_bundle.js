import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { initListboxInputs } from '~/vue_shared/components/listbox_input/init_listbox_inputs';
import ProfilePreferences from './components/profile_preferences.vue';
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

export default () => {
  initListboxInputs();
  initTextEditorPreference();
  initOrbitSubsettings();
  initColorModeSelector();

  const el = document.querySelector('#js-profile-preferences-app');
  const formEl = document.querySelector('#profile-preferences-form');
  const shouldParse = ['integrationViews', 'colorModes', 'themes', 'userFields'];

  const provide = Object.keys(el.dataset).reduce(
    (memo, key) => {
      let value = el.dataset[key];
      if (shouldParse.includes(key)) {
        value = JSON.parse(value);
      }

      return { ...memo, [key]: value };
    },
    { formEl },
  );

  return initVueApp({ el, name: 'ProfilePreferencesApp', provide, component: ProfilePreferences });
};
