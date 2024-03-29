import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { initListboxInputs } from '~/vue_shared/components/listbox_input/init_listbox_inputs';
import ProfilePreferences from './components/profile_preferences.vue';

export default () => {
  initListboxInputs();

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
