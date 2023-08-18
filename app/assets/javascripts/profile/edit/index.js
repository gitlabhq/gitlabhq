import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProfileEditApp from './components/profile_edit_app.vue';

export const initProfileEdit = () => {
  const mountEl = document.querySelector('.js-user-profile');

  if (!mountEl) return false;

  const {
    profilePath,
    userPath,
    currentEmoji,
    currentMessage,
    currentAvailability,
    defaultEmoji,
    currentClearStatusAfter,
    ...provides
  } = mountEl.dataset;

  return new Vue({
    el: mountEl,
    name: 'ProfileEditRoot',
    provide: {
      ...provides,
      currentEmoji,
      currentMessage,
      currentAvailability,
      defaultEmoji,
      currentClearStatusAfter,
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
