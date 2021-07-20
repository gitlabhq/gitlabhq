import {
  OPERATOR_IS,
  OPERATOR_IS_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';

export const getIssuesQueryResponse = {
  data: {
    project: {
      issues: {
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [
          {
            id: 'gid://gitlab/Issue/123456',
            iid: '789',
            closedAt: null,
            confidential: false,
            createdAt: '2021-05-22T04:08:01Z',
            downvotes: 2,
            dueDate: '2021-05-29',
            humanTimeEstimate: null,
            moved: false,
            title: 'Issue title',
            updatedAt: '2021-05-22T04:08:01Z',
            upvotes: 3,
            userDiscussionsCount: 4,
            webUrl: 'project/-/issues/789',
            assignees: {
              nodes: [
                {
                  id: 'gid://gitlab/User/234',
                  avatarUrl: 'avatar/url',
                  name: 'Marge Simpson',
                  username: 'msimpson',
                  webUrl: 'url/msimpson',
                },
              ],
            },
            author: {
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

export const getIssuesCountQueryResponse = {
  data: {
    project: {
      issues: {
        count: 1,
      },
    },
  },
};

export const locationSearch = [
  '?search=find+issues',
  'author_username=homer',
  'not[author_username]=marge',
  'assignee_username[]=bart',
  'assignee_username[]=lisa',
  'not[assignee_username][]=patty',
  'not[assignee_username][]=selma',
  'milestone_title=season+4',
  'not[milestone_title]=season+20',
  'label_name[]=cartoon',
  'label_name[]=tv',
  'not[label_name][]=live action',
  'not[label_name][]=drama',
  'my_reaction_emoji=thumbsup',
  'confidential=no',
  'iteration_id=4',
  'not[iteration_id]=20',
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
  'epic_id=None',
  'weight=None',
].join('&');

export const filteredTokens = [
  { type: 'author_username', value: { data: 'homer', operator: OPERATOR_IS } },
  { type: 'author_username', value: { data: 'marge', operator: OPERATOR_IS_NOT } },
  { type: 'assignee_username', value: { data: 'bart', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: 'lisa', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: 'patty', operator: OPERATOR_IS_NOT } },
  { type: 'assignee_username', value: { data: 'selma', operator: OPERATOR_IS_NOT } },
  { type: 'milestone', value: { data: 'season 4', operator: OPERATOR_IS } },
  { type: 'milestone', value: { data: 'season 20', operator: OPERATOR_IS_NOT } },
  { type: 'labels', value: { data: 'cartoon', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'tv', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'live action', operator: OPERATOR_IS_NOT } },
  { type: 'labels', value: { data: 'drama', operator: OPERATOR_IS_NOT } },
  { type: 'my_reaction_emoji', value: { data: 'thumbsup', operator: OPERATOR_IS } },
  { type: 'confidential', value: { data: 'no', operator: OPERATOR_IS } },
  { type: 'iteration', value: { data: '4', operator: OPERATOR_IS } },
  { type: 'iteration', value: { data: '20', operator: OPERATOR_IS_NOT } },
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
  { type: 'epic_id', value: { data: 'None', operator: OPERATOR_IS } },
  { type: 'weight', value: { data: 'None', operator: OPERATOR_IS } },
];

export const apiParams = {
  authorUsername: 'homer',
  assigneeUsernames: ['bart', 'lisa'],
  milestoneTitle: 'season 4',
  labelName: ['cartoon', 'tv'],
  myReactionEmoji: 'thumbsup',
  confidential: 'no',
  iterationId: '4',
  epicId: '12',
  weight: '1',
  not: {
    authorUsername: 'marge',
    assigneeUsernames: ['patty', 'selma'],
    milestoneTitle: 'season 20',
    labelName: ['live action', 'drama'],
    iterationId: '20',
    epicId: '34',
    weight: '3',
  },
};

export const apiParamsWithSpecialValues = {
  assigneeId: '123',
  assigneeUsernames: 'bart',
  myReactionEmoji: 'None',
  iterationWildcardId: 'CURRENT',
  epicId: 'None',
  weight: 'None',
};

export const urlParams = {
  author_username: 'homer',
  'not[author_username]': 'marge',
  'assignee_username[]': ['bart', 'lisa'],
  'not[assignee_username][]': ['patty', 'selma'],
  milestone_title: 'season 4',
  'not[milestone_title]': 'season 20',
  'label_name[]': ['cartoon', 'tv'],
  'not[label_name][]': ['live action', 'drama'],
  my_reaction_emoji: 'thumbsup',
  confidential: 'no',
  iteration_id: '4',
  'not[iteration_id]': '20',
  epic_id: '12',
  'not[epic_id]': '34',
  weight: '1',
  'not[weight]': '3',
};

export const urlParamsWithSpecialValues = {
  assignee_id: '123',
  'assignee_username[]': 'bart',
  my_reaction_emoji: 'None',
  iteration_id: 'Current',
  epic_id: 'None',
  weight: 'None',
};
