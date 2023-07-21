import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProfileEditApp from './components/profile_edit_app.vue';

export const initProfileEdit = () => {
  const mountEl = document.querySelector('.js-user-profile');

  if (!mountEl) return false;

  const { profilePath, userPath, ...provides } = mountEl.dataset;

  return new Vue({
    el: mountEl,
    name: 'ProfileEditRoot',
    provide: {
      ...provides,
      hasAvatar: parseBoolean(provides.hasAvatar),
      gravatarEnabled: parseBoolean(provides.gravatarEnabled),
      gravatarLink: JSON.parse(provides.gravatarLink),
    },
    render(createElement) {
      return createElement(ProfileEditApp, {
        props: {
          profilePath,
          userPath,
        },
      });
    },
  });
};
