import { __, s__ } from '~/locale';

// Matches `lib/gitlab/access.rb`
export const ACCESS_LEVEL_NO_ACCESS_INTEGER = 0;
export const ACCESS_LEVEL_MINIMAL_ACCESS_INTEGER = 5;
export const ACCESS_LEVEL_GUEST_INTEGER = 10;
export const ACCESS_LEVEL_REPORTER_INTEGER = 20;
export const ACCESS_LEVEL_DEVELOPER_INTEGER = 30;
export const ACCESS_LEVEL_MAINTAINER_INTEGER = 40;
export const ACCESS_LEVEL_OWNER_INTEGER = 50;
export const ACCESS_LEVEL_ADMIN_INTEGER = 60;

const ACCESS_LEVEL_NO_ACCESS = __('No access');
const ACCESS_LEVEL_MINIMAL_ACCESS = __('Minimal Access');
const ACCESS_LEVEL_GUEST = __('Guest');
const ACCESS_LEVEL_REPORTER = __('Reporter');
const ACCESS_LEVEL_DEVELOPER = __('Developer');
const ACCESS_LEVEL_MAINTAINER = __('Maintainer');
const ACCESS_LEVEL_OWNER = __('Owner');

export const BASE_ROLES = [
  {
    value: 'MINIMAL_ACCESS',
    text: ACCESS_LEVEL_MINIMAL_ACCESS,
    accessLevel: ACCESS_LEVEL_MINIMAL_ACCESS_INTEGER,
    memberRoleId: null,
    occupiesSeat: false,
    description: s__(
      'MemberRole|The Minimal Access role is for users who need the least amount of access into groups and projects. You can assign this role as a default, before giving a user another role with more permissions.',
    ),
  },
  {
    value: 'GUEST',
    text: ACCESS_LEVEL_GUEST,
    accessLevel: ACCESS_LEVEL_GUEST_INTEGER,
    memberRoleId: null,
    occupiesSeat: false,
    description: s__(
      'MemberRole|The Guest role is for users who need visibility into a project or group but should not have the ability to make changes, such as external stakeholders.',
    ),
  },
  {
    value: 'REPORTER',
    text: ACCESS_LEVEL_REPORTER,
    accessLevel: ACCESS_LEVEL_REPORTER_INTEGER,
    memberRoleId: null,
    occupiesSeat: true,
    description: s__(
      'MemberRole|The Reporter role is suitable for team members who need to stay informed about a project or group but do not actively contribute code.',
    ),
  },
  {
    value: 'DEVELOPER',
    text: ACCESS_LEVEL_DEVELOPER,
    accessLevel: ACCESS_LEVEL_DEVELOPER_INTEGER,
    memberRoleId: null,
    occupiesSeat: true,
    description: s__(
      'MemberRole|The Developer role strikes a balance between giving users the necessary access to contribute code while restricting sensitive administrative actions.',
    ),
  },
  {
    value: 'MAINTAINER',
    text: ACCESS_LEVEL_MAINTAINER,
    accessLevel: ACCESS_LEVEL_MAINTAINER_INTEGER,
    memberRoleId: null,
    occupiesSeat: true,
    description: s__(
      'MemberRole|The Maintainer role is primarily used for managing code reviews, approvals, and administrative settings for projects. This role can also manage project memberships.',
    ),
  },
  {
    value: 'OWNER',
    text: ACCESS_LEVEL_OWNER,
    accessLevel: ACCESS_LEVEL_OWNER_INTEGER,
    memberRoleId: null,
    occupiesSeat: true,
    description: s__(
      'MemberRole|The Owner role is normally assigned to the individual or team responsible for managing and maintaining the group or creating the project. This role has the highest level of administrative control, and can manage all aspects of the group or project, including managing other Owners.',
    ),
  },
];

export const ACCESS_LEVEL_LABELS = {
  [ACCESS_LEVEL_NO_ACCESS_INTEGER]: ACCESS_LEVEL_NO_ACCESS,
  [ACCESS_LEVEL_MINIMAL_ACCESS_INTEGER]: ACCESS_LEVEL_MINIMAL_ACCESS,
  [ACCESS_LEVEL_GUEST_INTEGER]: ACCESS_LEVEL_GUEST,
  [ACCESS_LEVEL_REPORTER_INTEGER]: ACCESS_LEVEL_REPORTER,
  [ACCESS_LEVEL_DEVELOPER_INTEGER]: ACCESS_LEVEL_DEVELOPER,
  [ACCESS_LEVEL_MAINTAINER_INTEGER]: ACCESS_LEVEL_MAINTAINER,
  [ACCESS_LEVEL_OWNER_INTEGER]: ACCESS_LEVEL_OWNER,
};
