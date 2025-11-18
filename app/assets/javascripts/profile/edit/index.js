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
    email,
    publicEmail,
    commitEmail,
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
    publicEmailOptions,
    commitEmailOptions,
    emailHelpText,
    emailResendConfirmationLink,
    isEmailReadonly,
    emailChangeDisabled,
    managingGroupName,
    needsPasswordConfirmation,
    providerLabel,
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
      publicEmailOptions: publicEmailOptions ? JSON.parse(publicEmailOptions) : [],
      commitEmailOptions: commitEmailOptions ? JSON.parse(commitEmailOptions) : [],
      emailResendConfirmationLink: emailResendConfirmationLink || '',
      emailHelpText: emailHelpText || '',
      isEmailReadonly: parseBoolean(isEmailReadonly),
      emailChangeDisabled: parseBoolean(emailChangeDisabled),
      managingGroupName: managingGroupName || '',
      needsPasswordConfirmation: parseBoolean(needsPasswordConfirmation),
      providerLabel: providerLabel || '',
      userSettings: {
        id: provides.id,
        name,
        email,
        publicEmail: publicEmail || '',
        commitEmail: commitEmail || '',
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
