import Vue from 'vue';
import ProfileEditApp from './components/profile_edit_app.vue';

export const initProfileEdit = () => {
  const mountEl = document.querySelector('.js-user-profile');

  if (!mountEl) return false;

  return new Vue({
    el: mountEl,
    name: 'ProfileEditRoot',
    render(createElement) {
      return createElement(ProfileEditApp);
    },
  });
};
