import {
  OPERATOR_IS,
  OPERATOR_IS_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';

export const getIssuesQueryResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      issues: {
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [
          {
            __typename: 'Issue',
            id: 'gid://gitlab/Issue/123456',
            iid: '789',
            confidential: false,
            createdAt: '2021-05-22T04:08:01Z',
            downvotes: 2,
            dueDate: '2021-05-29',
            hidden: false,
            humanTimeEstimate: null,
            mergeRequestsCount: false,
            moved: false,
            state: 'opened',
            title: 'Issue title',
            updatedAt: '2021-05-22T04:08:01Z',
            upvotes: 3,
            userDiscussionsCount: 4,
            webPath: 'project/-/issues/789',
            webUrl: 'project/-/issues/789',
            assignees: {
              nodes: [
                {
                  __typename: 'UserCore',
                  id: 'gid://gitlab/User/234',
                  avatarUrl: 'avatar/url',
                  name: 'Marge Simpson',
                  username: 'msimpson',
                  webUrl: 'url/msimpson',
                },
              ],
            },
            author: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/456',
              avatarUrl: 'avatar/url',
              name: 'Homer Simpson',
              username: 'hsimpson',
              webUrl: 'url/hsimpson',
            },
            labels: {
              nodes: [
                {
                  id: 'gid://gitlab/ProjectLabel/456',
                  color: '#333',
                  title: 'Label title',
                  description: 'Label description',
                },
              ],
            },
            milestone: null,
            taskCompletionStatus: {
              completedCount: 1,
              count: 2,
            },
          },
        ],
      },
    },
  },
};

export const getIssuesCountsQueryResponse = {
  data: {
    project: {
      id: '1',
      openedIssues: {
        count: 1,
      },
      closedIssues: {
        count: 1,
      },
      allIssues: {
        count: 1,
      },
    },
  },
};

export const setSortPreferenceMutationResponse = {
  data: {
    userPreferencesUpdate: {
      errors: [],
    },
  },
};

export const setSortPreferenceMutationResponseWithErrors = {
  data: {
    userPreferencesUpdate: {
      errors: ['oh no!'],
    },
  },
};

export const locationSearch = [
  '?search=find+issues',
  'author_username=homer',
  'not[author_username]=marge',
  'assignee_username[]=bart',
  'assignee_username[]=lisa',
  'assignee_username[]=5',
  'not[assignee_username][]=patty',
  'not[assignee_username][]=selma',
  'milestone_title=season+3',
  'milestone_title=season+4',
  'not[milestone_title]=season+20',
  'not[milestone_title]=season+30',
  'label_name[]=cartoon',
  'label_name[]=tv',
  'not[label_name][]=live action',
  'not[label_name][]=drama',
  'release_tag=v3',
  'release_tag=v4',
  'not[release_tag]=v20',
  'not[release_tag]=v30',
  'type[]=issue',
  'type[]=feature',
  'not[type][]=bug',
  'not[type][]=incident',
  'my_reaction_emoji=thumbsup',
  'not[my_reaction_emoji]=thumbsdown',
  'confidential=yes',
  'iteration_id=4',
  'iteration_id=12',
  'not[iteration_id]=20',
  'not[iteration_id]=42',
  'epic_id=12',
  'not[epic_id]=34',
  'weight=1',
  'not[weight]=3',
].join('&');

export const locationSearchWithSpecialValues = [
  'assignee_id=123',
  'assignee_username=bart',
  'my_reaction_emoji=None',
  'iteration_id=Current',
  'label_name[]=None',
  'release_tag=None',
  'milestone_title=Upcoming',
  'epic_id=None',
  'weight=None',
].join('&');

export const filteredTokens = [
  { type: 'author_username', value: { data: 'homer', operator: OPERATOR_IS } },
  { type: 'author_username', value: { data: 'marge', operator: OPERATOR_IS_NOT } },
  { type: 'assignee_username', value: { data: 'bart', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: 'lisa', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: '5', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: 'patty', operator: OPERATOR_IS_NOT } },
  { type: 'assignee_username', value: { data: 'selma', operator: OPERATOR_IS_NOT } },
  { type: 'milestone', value: { data: 'season 3', operator: OPERATOR_IS } },
  { type: 'milestone', value: { data: 'season 4', operator: OPERATOR_IS } },
  { type: 'milestone', value: { data: 'season 20', operator: OPERATOR_IS_NOT } },
  { type: 'milestone', value: { data: 'season 30', operator: OPERATOR_IS_NOT } },
  { type: 'labels', value: { data: 'cartoon', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'tv', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'live action', operator: OPERATOR_IS_NOT } },
  { type: 'labels', value: { data: 'drama', operator: OPERATOR_IS_NOT } },
  { type: 'release', value: { data: 'v3', operator: OPERATOR_IS } },
  { type: 'release', value: { data: 'v4', operator: OPERATOR_IS } },
  { type: 'release', value: { data: 'v20', operator: OPERATOR_IS_NOT } },
  { type: 'release', value: { data: 'v30', operator: OPERATOR_IS_NOT } },
  { type: 'type', value: { data: 'issue', operator: OPERATOR_IS } },
  { type: 'type', value: { data: 'feature', operator: OPERATOR_IS } },
  { type: 'type', value: { data: 'bug', operator: OPERATOR_IS_NOT } },
  { type: 'type', value: { data: 'incident', operator: OPERATOR_IS_NOT } },
  { type: 'my_reaction_emoji', value: { data: 'thumbsup', operator: OPERATOR_IS } },
  { type: 'my_reaction_emoji', value: { data: 'thumbsdown', operator: OPERATOR_IS_NOT } },
  { type: 'confidential', value: { data: 'yes', operator: OPERATOR_IS } },
  { type: 'iteration', value: { data: '4', operator: OPERATOR_IS } },
  { type: 'iteration', value: { data: '12', operator: OPERATOR_IS } },
  { type: 'iteration', value: { data: '20', operator: OPERATOR_IS_NOT } },
  { type: 'iteration', value: { data: '42', operator: OPERATOR_IS_NOT } },
  { type: 'epic_id', value: { data: '12', operator: OPERATOR_IS } },
  { type: 'epic_id', value: { data: '34', operator: OPERATOR_IS_NOT } },
  { type: 'weight', value: { data: '1', operator: OPERATOR_IS } },
  { type: 'weight', value: { data: '3', operator: OPERATOR_IS_NOT } },
  { type: 'filtered-search-term', value: { data: 'find' } },
  { type: 'filtered-search-term', value: { data: 'issues' } },
];

export const filteredTokensWithSpecialValues = [
  { type: 'assignee_username', value: { data: '123', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: 'bart', operator: OPERATOR_IS } },
  { type: 'my_reaction_emoji', value: { data: 'None', operator: OPERATOR_IS } },
  { type: 'iteration', value: { data: 'Current', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'None', operator: OPERATOR_IS } },
  { type: 'release', value: { data: 'None', operator: OPERATOR_IS } },
  { type: 'milestone', value: { data: 'Upcoming', operator: OPERATOR_IS } },
  { type: 'epic_id', value: { data: 'None', operator: OPERATOR_IS } },
  { type: 'weight', value: { data: 'None', operator: OPERATOR_IS } },
];

export const apiParams = {
  authorUsername: 'homer',
  assigneeUsernames: ['bart', 'lisa', '5'],
  milestoneTitle: ['season 3', 'season 4'],
  labelName: ['cartoon', 'tv'],
  releaseTag: ['v3', 'v4'],
  types: ['ISSUE', 'FEATURE'],
  myReactionEmoji: 'thumbsup',
  confidential: true,
  iterationId: ['4', '12'],
  epicId: '12',
  weight: '1',
  not: {
    authorUsername: 'marge',
    assigneeUsernames: ['patty', 'selma'],
    milestoneTitle: ['season 20', 'season 30'],
    labelName: ['live action', 'drama'],
    releaseTag: ['v20', 'v30'],
    types: ['BUG', 'INCIDENT'],
    myReactionEmoji: 'thumbsdown',
    iterationId: ['20', '42'],
    epicId: '34',
    weight: '3',
  },
};

export const apiParamsWithSpecialValues = {
  assigneeId: '123',
  assigneeUsernames: 'bart',
  labelName: 'None',
  myReactionEmoji: 'None',
  releaseTagWildcardId: 'NONE',
  iterationWildcardId: 'CURRENT',
  milestoneWildcardId: 'UPCOMING',
  epicId: 'None',
  weight: 'None',
};

export const urlParams = {
  author_username: 'homer',
  'not[author_username]': 'marge',
  'assignee_username[]': ['bart', 'lisa', '5'],
  'not[assignee_username][]': ['patty', 'selma'],
  milestone_title: ['season 3', 'season 4'],
  'not[milestone_title]': ['season 20', 'season 30'],
  'label_name[]': ['cartoon', 'tv'],
  'not[label_name][]': ['live action', 'drama'],
  release_tag: ['v3', 'v4'],
  'not[release_tag]': ['v20', 'v30'],
  'type[]': ['issue', 'feature'],
  'not[type][]': ['bug', 'incident'],
  my_reaction_emoji: 'thumbsup',
  'not[my_reaction_emoji]': 'thumbsdown',
  confidential: 'yes',
  iteration_id: ['4', '12'],
  'not[iteration_id]': ['20', '42'],
  epic_id: '12',
  'not[epic_id]': '34',
  weight: '1',
  'not[weight]': '3',
};

export const urlParamsWithSpecialValues = {
  assignee_id: '123',
  'assignee_username[]': 'bart',
  'label_name[]': 'None',
  release_tag: 'None',
  my_reaction_emoji: 'None',
  iteration_id: 'Current',
  milestone_title: 'Upcoming',
  epic_id: 'None',
  weight: 'None',
};

export const project1 = {
  id: 'gid://gitlab/Group/26',
  issuesEnabled: true,
  name: 'Super Mario Project',
  nameWithNamespace: 'Mushroom Kingdom / Super Mario Project',
  webUrl: 'https://127.0.0.1:3000/mushroom-kingdom/super-mario-project',
};

export const project2 = {
  id: 'gid://gitlab/Group/59',
  issuesEnabled: false,
  name: 'Mario Kart Project',
  nameWithNamespace: 'Mushroom Kingdom / Mario Kart Project',
  webUrl: 'https://127.0.0.1:3000/mushroom-kingdom/mario-kart-project',
};

export const project3 = {
  id: 'gid://gitlab/Group/103',
  issuesEnabled: true,
  name: 'Mario Party Project',
  nameWithNamespace: 'Mushroom Kingdom / Mario Party Project',
  webUrl: 'https://127.0.0.1:3000/mushroom-kingdom/mario-party-project',
};

export const searchProjectsQueryResponse = {
  data: {
    group: {
      id: '1',
      projects: {
        nodes: [project1, project2, project3],
      },
    },
  },
};

export const emptySearchProjectsQueryResponse = {
  data: {
    group: {
      id: '1',
      projects: {
        nodes: [],
      },
    },
  },
};
