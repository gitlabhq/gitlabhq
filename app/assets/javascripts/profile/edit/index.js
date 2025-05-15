import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProfileEditApp from './components/profile_edit_app.vue';

export const initProfileEdit = () => {
  const mountEl = document.querySelector('.js-user-profile-edit');

  if (!mountEl) return false;

  const {
    profilePath,
    userPath,
    currentEmoji,
    currentMessage,
    currentAvailability,
    defaultEmoji,
    currentClearStatusAfter,
    timezones,
    userTimezone,
    userId,
    name,
    pronouns,
    pronunciation,
    websiteUrl,
    location,
    jobTitle,
    organization,
    bio,
    privateProfile,
    includePrivateContributions,
    achievementsEnabled,
    ...provides
  } = mountEl.dataset;

  return new Vue({
    el: mountEl,
    name: 'ProfileEditRoot',
    provide: {
      ...provides,
      name,
      pronouns,
      pronunciation,
      websiteUrl,
      location,
      jobTitle,
      organization,
      bio,
      privateProfile: parseBoolean(privateProfile),
      includePrivateContributions: parseBoolean(includePrivateContributions),
      achievementsEnabled: parseBoolean(achievementsEnabled),
      currentEmoji,
      currentMessage,
      currentAvailability,
      defaultEmoji,
      currentClearStatusAfter,
      hasAvatar: parseBoolean(provides.hasAvatar),
      gravatarEnabled: parseBoolean(provides.gravatarEnabled),
      gravatarLink: JSON.parse(provides.gravatarLink),
      timezones: JSON.parse(timezones),
      userTimezone,
      userMainSettings: {
        id: provides.id,
        name,
        pronouns,
        pronunciation,
        websiteUrl,
        location,
        jobTitle,
        organization,
        bio,
        privateProfile,
        includePrivateContributions,
        achievementsEnabled,
      },
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
