import { s__, __ } from '~/locale';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
} from '~/visibility_level/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

export const visibilityLevelDescriptions = {
  [VISIBILITY_LEVEL_PRIVATE_INTEGER]: __(
    `Only accessible by %{membersPageLinkStart}project members%{membersPageLinkEnd}. Membership must be explicitly granted to each user.`,
  ),
  [VISIBILITY_LEVEL_INTERNAL_INTEGER]: __('Accessible by any user who is logged in.'),
  [VISIBILITY_LEVEL_PUBLIC_INTEGER]: __('Accessible by anyone, regardless of authentication.'),
};

export const featureAccessLevel = {
  NOT_ENABLED: 0,
  PROJECT_MEMBERS: 10,
  EVERYONE: 20,
};

export const featureAccessLevelDescriptions = {
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

export const modelExperimentsHelpPath = helpPagePath(
  'user/project/ml/experiment_tracking/index.md',
);

export const modelRegistryHelpPath = helpPagePath('user/project/ml/model_registry/index.md');

export const duoHelpPath = helpPagePath('user/ai_features');
