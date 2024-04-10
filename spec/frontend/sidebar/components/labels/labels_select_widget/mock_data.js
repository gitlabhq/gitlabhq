export const mockRegularLabel = {
  id: 26,
  title: 'Foo Label',
  description: 'Foobar',
  color: '#BADA55',
  textColor: '#FFFFFF',
};

export const mockScopedLabel = {
  id: 27,
  title: 'Foo::Bar',
  description: 'Foobar',
  color: '#0033CC',
  textColor: '#FFFFFF',
};

export const mockLockedLabel = {
  id: 30,
  title: 'Bar Label',
  description: 'Bar',
  color: '#DADA55',
  textColor: '#FFFFFF',
  lockOnMerge: true,
  lock_on_merge: true,
};

export const mockLabels = [
  mockRegularLabel,
  mockScopedLabel,
  {
    id: 28,
    title: 'Bug',
    description: 'Label for bugs',
    color: '#FF0000',
    textColor: '#FFFFFF',
  },
  {
    id: 29,
    title: 'Boog',
    description: 'Label for bugs',
    color: '#FF0000',
    textColor: '#FFFFFF',
  },
];

export const mockConfig = {
  iid: '1',
  fullPath: 'test',
  allowMultiselect: true,
  labelsListTitle: 'Select labels',
  labelsCreateTitle: 'Create label',
  variant: 'sidebar',
  labelsSelectInProgress: false,
  labelsFilterBasePath: '/gitlab-org/my-project/issues',
  labelsFilterParam: 'label_name',
  footerCreateLabelTitle: 'create',
  footerManageLabelTitle: 'manage',
  attrWorkspacePath: 'test',
};

export const createLabelSuccessfulResponse = {
  data: {
    labelCreate: {
      label: {
        id: 'gid://gitlab/ProjectLabel/126',
        color: '#dc143c',
        description: null,
        title: 'ewrwrwer',
        textColor: '#000000',
        __typename: 'Label',
      },
      errors: [],
      __typename: 'LabelCreatePayload',
    },
  },
};

export const workspaceLabelsQueryResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/126',
      labels: {
        nodes: [
          {
            __typename: 'Label',
            color: '#330066',
            description: null,
            id: 'gid://gitlab/ProjectLabel/1',
            title: 'Label1',
            textColor: '#000000',
          },
          {
            __typename: 'Label',
            color: '#2f7b2e',
            description: null,
            id: 'gid://gitlab/ProjectLabel/2',
            title: 'Label2',
            textColor: '#000000',
          },
        ],
      },
    },
  },
};

export const workspaceLabelsQueryEmptyResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Project/126',
      labels: {
        nodes: [],
      },
    },
  },
};

export const issuableLabelsQueryResponse = {
  data: {
    workspace: {
      id: 'workspace-1',
      issuable: {
        __typename: 'Issue',
        id: '1',
        labels: {
          nodes: [
            {
              __typename: 'Label',
              color: '#330066',
              description: null,
              id: 'gid://gitlab/ProjectLabel/1',
              title: 'Label1',
              textColor: '#000000',
            },
          ],
        },
      },
    },
  },
};

export const issuableLabelsSubscriptionResponse = {
  data: {
    issuableLabelsUpdated: {
      id: '1',
      labels: {
        nodes: [
          {
            __typename: 'Label',
            color: '#330066',
            description: null,
            id: 'gid://gitlab/ProjectLabel/1',
            title: 'Label1',
            textColor: '#000000',
          },
          {
            __typename: 'Label',
            color: '#000000',
            description: null,
            id: 'gid://gitlab/ProjectLabel/2',
            title: 'Label2',
            textColor: '#ffffff',
          },
        ],
      },
    },
  },
};

export const updateLabelsMutationResponse = {
  data: {
    updateIssuableLabels: {
      errors: [],
      issuable: {
        updatedAt: '2023-02-10T22:26:49Z',
        updatedBy: {
          id: 'gid://gitlab/User/1',
          avatarUrl: 'avatar/url',
          name: 'John Smith',
          username: 'jsmith',
          webUrl: 'http://gdk.test:3000/jsmith',
          webPath: '/jsmith',
          __typename: 'UserCore',
        },
        __typename: 'Issue',
        id: '1',
        labels: {
          nodes: [],
        },
      },
    },
  },
};
