import { s__, __ } from '~/locale';

export const visibilityOptions = {
  PRIVATE: 0,
  INTERNAL: 10,
  PUBLIC: 20,
};

export const visibilityLevelDescriptions = {
  [visibilityOptions.PRIVATE]: __(
    'The project is accessible only by members of the project. Access must be granted explicitly to each user.',
  ),
  [visibilityOptions.INTERNAL]: __('The project can be accessed by any user who is logged in.'),
  [visibilityOptions.PUBLIC]: __(
    'The project can be accessed by anyone, regardless of authentication.',
  ),
};

export const featureAccessLevel = {
  NOT_ENABLED: 0,
  PROJECT_MEMBERS: 10,
  EVERYONE: 20,
};

const featureAccessLevelDescriptions = {
  [featureAccessLevel.NOT_ENABLED]: __('Enable feature to choose access level'),
  [featureAccessLevel.PROJECT_MEMBERS]: __('Only Project Members'),
  [featureAccessLevel.EVERYONE]: __('Everyone With Access'),
};

export const featureAccessLevelNone = [
  featureAccessLevel.NOT_ENABLED,
  featureAccessLevelDescriptions[featureAccessLevel.NOT_ENABLED],
];

export const featureAccessLevelMembers = [
  featureAccessLevel.PROJECT_MEMBERS,
  featureAccessLevelDescriptions[featureAccessLevel.PROJECT_MEMBERS],
];

export const featureAccessLevelEveryone = [
  featureAccessLevel.EVERYONE,
  featureAccessLevelDescriptions[featureAccessLevel.EVERYONE],
];

export const CVE_ID_REQUEST_BUTTON_I18N = {
  cve_request_toggle_label: s__('CVE|Enable CVE ID requests in the issue sidebar'),
};
