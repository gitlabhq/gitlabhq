import { s__ } from '~/locale';

export const CLOSE_TO_LIMIT_COUNT = 2;
export const SEARCH_DELAY = 200;
export const INVITE_MEMBERS_FOR_TASK = {
  minimum_access_level: 30,
  name: 'invite_members_for_task',
  view: 'modal_opened_from_email',
  submit: 'submit',
};

export const GROUP_FILTERS = {
  ALL: 'all',
  DESCENDANT_GROUPS: 'descendant_groups',
};

export const USERS_FILTER_ALL = 'all';
export const USERS_FILTER_SAML_PROVIDER_ID = 'saml_provider_id';
export const TRIGGER_ELEMENT_BUTTON = 'button';
export const TRIGGER_ELEMENT_SIDE_NAV = 'side-nav';
export const TRIGGER_DEFAULT_QA_SELECTOR = 'invite_members_button';
export const MEMBERS_MODAL_DEFAULT_TITLE = s__('InviteMembersModal|Invite members');
export const MEMBERS_MODAL_CELEBRATE_TITLE = s__(
  'InviteMembersModal|GitLab is better with colleagues!',
);
export const MEMBERS_MODAL_CELEBRATE_INTRO = s__(
  'InviteMembersModal|How about inviting a colleague or two to join you?',
);
export const MEMBERS_TO_GROUP_DEFAULT_INTRO_TEXT = s__(
  "InviteMembersModal|You're inviting members to the %{strongStart}%{name}%{strongEnd} group.",
);

export const MEMBERS_TO_PROJECT_DEFAULT_INTRO_TEXT = s__(
  "InviteMembersModal|You're inviting members to the %{strongStart}%{name}%{strongEnd} project.",
);
export const MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT = s__(
  "InviteMembersModal|Congratulations on creating your project, you're almost there!",
);
export const MEMBERS_SEARCH_FIELD = s__('InviteMembersModal|Username or email address');
export const MEMBERS_PLACEHOLDER = s__('InviteMembersModal|Select members or type email addresses');
export const MEMBERS_PLACEHOLDER_DISABLED = s__(
  'InviteMembersModal|This feature is disabled until this group has space for more members.',
);
export const MEMBERS_TASKS_TO_BE_DONE_TITLE = s__(
  'InviteMembersModal|Create issues for your new team member to work on (optional)',
);
export const MEMBERS_TASKS_TO_BE_DONE_NO_PROJECTS = s__(
  'InviteMembersModal|To assign issues to a new team member, you need a project for the issues. %{linkStart}Create a project to get started.%{linkEnd}',
);
export const MEMBERS_TASKS_PROJECTS_TITLE = s__(
  'InviteMembersModal|Choose a project for the issues',
);

export const GROUP_MODAL_DEFAULT_TITLE = s__('InviteMembersModal|Invite a group');
export const GROUP_MODAL_TO_GROUP_DEFAULT_INTRO_TEXT = s__(
  "InviteMembersModal|You're inviting a group to the %{strongStart}%{name}%{strongEnd} group.",
);
export const GROUP_MODAL_TO_PROJECT_DEFAULT_INTRO_TEXT = s__(
  "InviteMembersModal|You're inviting a group to the %{strongStart}%{name}%{strongEnd} project.",
);

export const GROUP_SEARCH_FIELD = s__('InviteMembersModal|Select a group to invite');
export const GROUP_PLACEHOLDER = s__('InviteMembersModal|Search for a group to invite');

export const ACCESS_LEVEL = s__('InviteMembersModal|Select a role');
export const ACCESS_EXPIRE_DATE = s__('InviteMembersModal|Access expiration date (optional)');
export const TOAST_MESSAGE_SUCCESSFUL = s__('InviteMembersModal|Members were successfully added');
export const INVALID_FEEDBACK_MESSAGE_DEFAULT = s__('InviteMembersModal|Something went wrong');
export const READ_MORE_TEXT = s__(
  `InviteMembersModal|%{linkStart}Read more%{linkEnd} about role permissions`,
);
export const INVITE_BUTTON_TEXT = s__('InviteMembersModal|Invite');
export const INVITE_BUTTON_TEXT_DISABLED = s__('InviteMembersModal|Manage members');
export const CANCEL_BUTTON_TEXT = s__('InviteMembersModal|Cancel');
export const CANCEL_BUTTON_TEXT_DISABLED = s__('InviteMembersModal|Explore paid plans');
export const HEADER_CLOSE_LABEL = s__('InviteMembersModal|Close invite team members');
export const MEMBER_ERROR_LIST_TEXT = s__(
  'InviteMembersModal|Review the invite errors and try again:',
);

export const MEMBER_MODAL_LABELS = {
  modal: {
    default: {
      title: MEMBERS_MODAL_DEFAULT_TITLE,
    },
    celebrate: {
      title: MEMBERS_MODAL_CELEBRATE_TITLE,
      intro: MEMBERS_MODAL_CELEBRATE_INTRO,
    },
  },
  toGroup: {
    default: {
      introText: MEMBERS_TO_GROUP_DEFAULT_INTRO_TEXT,
    },
  },
  toProject: {
    default: {
      introText: MEMBERS_TO_PROJECT_DEFAULT_INTRO_TEXT,
    },
    celebrate: {
      introText: MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT,
    },
  },
  searchField: MEMBERS_SEARCH_FIELD,
  placeHolder: MEMBERS_PLACEHOLDER,
  placeHolderDisabled: MEMBERS_PLACEHOLDER_DISABLED,
  tasksToBeDone: {
    title: MEMBERS_TASKS_TO_BE_DONE_TITLE,
    noProjects: MEMBERS_TASKS_TO_BE_DONE_NO_PROJECTS,
  },
  tasksProject: {
    title: MEMBERS_TASKS_PROJECTS_TITLE,
  },
  toastMessageSuccessful: TOAST_MESSAGE_SUCCESSFUL,
  memberErrorListText: MEMBER_ERROR_LIST_TEXT,
};

export const GROUP_MODAL_LABELS = {
  title: GROUP_MODAL_DEFAULT_TITLE,
  toGroup: {
    introText: GROUP_MODAL_TO_GROUP_DEFAULT_INTRO_TEXT,
  },
  toProject: {
    introText: GROUP_MODAL_TO_PROJECT_DEFAULT_INTRO_TEXT,
  },
  searchField: GROUP_SEARCH_FIELD,
  placeHolder: GROUP_PLACEHOLDER,
  toastMessageSuccessful: TOAST_MESSAGE_SUCCESSFUL,
};

export const LEARN_GITLAB = 'learn_gitlab';
export const ON_SHOW_TRACK_LABEL = 'locked_modal_viewed';
export const ON_CLOSE_TRACK_LABEL = 'explore_paid_plans_clicked';
export const ON_SUBMIT_TRACK_LABEL = 'manage_members_clicked';

export const WARNING_ALERT_TITLE = s__(
  'InviteMembersModal|You only have space for %{count} more %{members} in %{name}',
);
export const WARNING_ALERT_TITLE_PERSONAL_NAMESPACE = s__(
  'InviteMembersModal|You only have space for %{count} more %{members} in your personal projects',
);
export const DANGER_ALERT_TITLE = s__(
  "InviteMembersModal|You've reached your %{count} %{members} limit for %{name}",
);

export const DANGER_ALERT_TITLE_PERSONAL_NAMESPACE = s__(
  "InviteMembersModal|You've reached your %{count} %{members} limit for your personal projects",
);

export const REACHED_LIMIT_MESSAGE = s__(
  'InviteMembersModal|You cannot add more members, but you can remove members who no longer need access.',
);

export const REACHED_LIMIT_UPGRADE_SUGGESTION_MESSAGE = REACHED_LIMIT_MESSAGE.concat(
  s__(
    'InviteMembersModal| To get more members and access to additional paid features, an owner of this namespace can start a trial or upgrade to a paid tier.',
  ),
);

export const CLOSE_TO_LIMIT_MESSAGE = s__(
  'InviteMembersModal|To get more members an owner of this namespace can %{trialLinkStart}start a trial%{trialLinkEnd} or %{upgradeLinkStart}upgrade%{upgradeLinkEnd} to a paid tier.',
);
export const CLOSE_TO_LIMIT_MESSAGE_PERSONAL_NAMESPACE = s__(
  'InviteMembersModal|To make more space, you can remove members who no longer need access.',
);
