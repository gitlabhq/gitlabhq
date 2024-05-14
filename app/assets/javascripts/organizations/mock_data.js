/* eslint-disable @gitlab/require-i18n-strings */

// This is temporary mock data that will be removed when completing the following:
// https://gitlab.com/gitlab-org/gitlab/-/issues/420777
// https://gitlab.com/gitlab-org/gitlab/-/issues/421441

export const defaultOrganization = {
  id: 1,
  name: 'Default',
  web_url: '/-/organizations/default',
  avatar_url: null,
};

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
