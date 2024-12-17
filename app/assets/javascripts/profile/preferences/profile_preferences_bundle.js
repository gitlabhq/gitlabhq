import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { initListboxInputs } from '~/vue_shared/components/listbox_input/init_listbox_inputs';
import ProfilePreferences from './components/profile_preferences.vue';

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

export default () => {
  initListboxInputs();
  initTextEditorPreference();

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

  Vue.use(GlToast);

  return new Vue({
    el,
    name: 'ProfilePreferencesApp',
    provide,
    render: (createElement) => createElement(ProfilePreferences),
  });
};
