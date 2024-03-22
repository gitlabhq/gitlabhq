/* eslint-disable @gitlab/require-i18n-strings */

// This is temporary mock data that will be removed when completing the following:
// https://gitlab.com/gitlab-org/gitlab/-/issues/420777
// https://gitlab.com/gitlab-org/gitlab/-/issues/421441

import { organizationProjects } from 'ee_else_ce/organizations/mock_projects';
import { organizationGroups } from 'ee_else_ce/organizations/mock_groups';

export { organizationProjects, organizationGroups };

export const defaultOrganization = {
  id: 1,
  name: 'Default',
  web_url: '/-/organizations/default',
  avatar_url: null,
};

export const organizations = [
  {
    id: 'gid://gitlab/Organizations::Organization/1',
    name: 'My First Organization',
    descriptionHtml:
      '<p>This is where an organization can be explained in <strong>detail</strong></p>',
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61',
    webUrl: '/-/organizations/default',
    __typename: 'Organization',
  },
  {
    id: 'gid://gitlab/Organizations::Organization/2',
    name: 'Vegetation Co.',
    descriptionHtml:
      '<p> Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolt   Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt<script>alert(1)</script></p>',
    avatarUrl: null,
    webUrl: '/-/organizations/default',
    __typename: 'Organization',
  },
  {
    id: 'gid://gitlab/Organizations::Organization/3',
    name: 'Dude where is my car?',
    descriptionHtml: null,
    avatarUrl: null,
    webUrl: '/-/organizations/default',
    __typename: 'Organization',
  },
];

export const organizationCreateResponse = {
  data: {
    organizationCreate: {
      organization: {
        id: 'gid://gitlab/Organizations::Organization/1',
        webUrl: 'http://127.0.0.1:3000/-/organizations/default',
      },
      errors: [],
    },
  },
};

export const organizationCreateResponseWithErrors = {
  data: {
    organizationCreate: {
      organization: null,
      errors: ['Path is too short (minimum is 2 characters)'],
    },
  },
};

export const organizationUpdateResponse = {
  data: {
    organizationUpdate: {
      organization: {
        id: 'gid://gitlab/Organizations::Organization/1',
        name: 'Default updated',
        webUrl: 'http://127.0.0.1:3000/-/organizations/default',
      },
      errors: [],
    },
  },
};

export const organizationUpdateResponseWithErrors = {
  data: {
    organizationUpdate: {
      organization: null,
      errors: ['Path is too short (minimum is 2 characters)'],
    },
  },
};

export const pageInfo = {
  endCursor: 'eyJpZCI6IjEwNTMifQ',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjEwNzIifQ',
  __typename: 'PageInfo',
};

export const pageInfoOnePage = {
  endCursor: 'eyJpZCI6IjEwNTMifQ',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: 'eyJpZCI6IjEwNzIifQ',
  __typename: 'PageInfo',
};

export const pageInfoEmpty = {
  endCursor: null,
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  __typename: 'PageInfo',
};
