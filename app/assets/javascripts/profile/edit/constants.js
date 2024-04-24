import { s__, __ } from '~/locale';

export const avatarI18n = {
  publicAvatar: s__('Profiles|Public avatar'),
  changeOrRemoveAvatar: s__(
    'Profiles|You can change your avatar here or remove the current avatar to revert to %{gravatar_link}',
  ),
  changeAvatar: s__('Profiles|You can change your avatar here'),
  uploadOrChangeAvatar: s__(
    'Profiles|You can upload your avatar here or change it at %{gravatar_link}',
  ),
  uploadAvatar: s__('Profiles|You can upload your avatar here'),
  uploadNewAvatar: s__('Profiles|Upload new avatar'),
  chooseFile: s__('Profiles|Choose file...'),
  noFileChosen: s__('Profiles|No file chosen.'),
  maximumFileSize: s__('Profiles|The maximum file size allowed is 200 KiB.'),
  imageDimensions: s__('Profiles|The ideal image size is 192 x 192 pixels.'),
  removeAvatar: s__('Profiles|Remove avatar'),
  removeAvatarConfirmation: s__('Profiles|Avatar will be removed. Are you sure?'),
  cropAvatarTitle: s__('Profiles|Position and size your new avatar'),
  cropAvatarImageAltText: s__('Profiles|Avatar cropper'),
  cropAvatarSetAsNewAvatar: s__('Profiles|Set new profile picture'),
};

export const statusI18n = {
  setStatusTitle: s__('Profiles|Current status'),
  setStatusDescription: s__(
    'Profiles|This emoji and message will appear on your profile and throughout the interface.',
  ),
};

export const timezoneI18n = {
  setTimezoneTitle: s__('Profiles|Time settings'),
  setTimezoneDescription: s__('Profiles|Set your local time zone.'),
};

export const i18n = {
  updateProfileSettings: s__('Profiles|Update profile settings'),
  cancel: __('Cancel'),
};
