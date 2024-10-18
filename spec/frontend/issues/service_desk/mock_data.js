import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  OPERATOR_NOT,
  OPERATOR_OR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_WEIGHT,
  TOKEN_TYPE_HEALTH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

export const getServiceDeskIssuesQueryResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      issues: {
        __persist: true,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [
          {
            __persist: true,
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
            closedAt: null,
            upvotes: 3,
            userDiscussionsCount: 4,
            webPath: 'project/-/issues/789',
            webUrl: 'project/-/issues/789',
            type: 'issue',
            assignees: {
              nodes: [
                {
                  __persist: true,
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
              __persist: true,
              __typename: 'UserCore',
              id: 'gid://gitlab/User/456',
              avatarUrl: 'avatar/url',
              name: 'GitLab Support Bot',
              username: 'support-bot',
              webUrl: 'url/hsimpson',
            },
            externalAuthor: 'client@client.com',
            labels: {
              nodes: [
                {
                  __persist: true,
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

export const getServiceDeskIssuesQueryEmptyResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      issues: {
        __persist: true,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [],
      },
    },
  },
};

export const getServiceDeskIssuesCountsQueryResponse = {
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

export const filteredTokens = [
  { type: FILTERED_SEARCH_TERM, value: { data: 'find issues', operator: 'undefined' } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'bart', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'lisa', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: '5', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'patty', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'selma', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'carl', operator: OPERATOR_OR } },
  { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'lenny', operator: OPERATOR_OR } },
  { type: TOKEN_TYPE_MILESTONE, value: { data: 'season 3', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_MILESTONE, value: { data: 'season 4', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_MILESTONE, value: { data: 'season 20', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_MILESTONE, value: { data: 'season 30', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_LABEL, value: { data: 'cartoon', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_LABEL, value: { data: 'tv', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_LABEL, value: { data: 'live action', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_LABEL, value: { data: 'drama', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_LABEL, value: { data: 'comedy', operator: OPERATOR_OR } },
  { type: TOKEN_TYPE_LABEL, value: { data: 'sitcom', operator: OPERATOR_OR } },
  { type: TOKEN_TYPE_RELEASE, value: { data: 'v3', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_RELEASE, value: { data: 'v4', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_RELEASE, value: { data: 'v20', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_RELEASE, value: { data: 'v30', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_MY_REACTION, value: { data: EMOJI_THUMBS_UP, operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_MY_REACTION, value: { data: EMOJI_THUMBS_DOWN, operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_CONFIDENTIAL, value: { data: 'yes', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_ITERATION, value: { data: '4', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_ITERATION, value: { data: '12', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_ITERATION, value: { data: '20', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_ITERATION, value: { data: '42', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_EPIC, value: { data: '12', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_EPIC, value: { data: '34', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_WEIGHT, value: { data: '1', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_WEIGHT, value: { data: '3', operator: OPERATOR_NOT } },
  { type: TOKEN_TYPE_HEALTH, value: { data: 'atRisk', operator: OPERATOR_IS } },
  { type: TOKEN_TYPE_HEALTH, value: { data: 'onTrack', operator: OPERATOR_NOT } },
];

export const urlParams = {
  search: 'find issues',
  'assignee_username[]': ['bart', 'lisa', '5'],
  'not[assignee_username][]': ['patty', 'selma'],
  'or[assignee_username][]': ['carl', 'lenny'],
  milestone_title: ['season 3', 'season 4'],
  'not[milestone_title]': ['season 20', 'season 30'],
  'label_name[]': ['cartoon', 'tv'],
  'not[label_name][]': ['live action', 'drama'],
  'or[label_name][]': ['comedy', 'sitcom'],
  release_tag: ['v3', 'v4'],
  'not[release_tag]': ['v20', 'v30'],
  my_reaction_emoji: EMOJI_THUMBS_UP,
  'not[my_reaction_emoji]': EMOJI_THUMBS_DOWN,
  confidential: 'yes',
  iteration_id: ['4', '12'],
  'not[iteration_id]': ['20', '42'],
  epic_id: '12',
  'not[epic_id]': '34',
  weight: '1',
  'not[weight]': '3',
  health_status: 'atRisk',
  'not[health_status]': 'onTrack',
};

export const locationSearch = [
  '?search=find+issues',
  'assignee_username[]=bart',
  'assignee_username[]=lisa',
  'assignee_username[]=5',
  'not[assignee_username][]=patty',
  'not[assignee_username][]=selma',
  'or[assignee_username][]=carl',
  'or[assignee_username][]=lenny',
  'milestone_title=season+3',
  'milestone_title=season+4',
  'not[milestone_title]=season+20',
  'not[milestone_title]=season+30',
  'label_name[]=cartoon',
  'label_name[]=tv',
  'not[label_name][]=live action',
  'not[label_name][]=drama',
  'or[label_name][]=comedy',
  'or[label_name][]=sitcom',
  'release_tag=v3',
  'release_tag=v4',
  'not[release_tag]=v20',
  'not[release_tag]=v30',
  `my_reaction_emoji=${EMOJI_THUMBS_UP}`,
  `not[my_reaction_emoji]=${EMOJI_THUMBS_DOWN}`,
  'confidential=yes',
  'iteration_id=4',
  'iteration_id=12',
  'not[iteration_id]=20',
  'not[iteration_id]=42',
  'epic_id=12',
  'not[epic_id]=34',
  'weight=1',
  'not[weight]=3',
  'health_status=atRisk',
  'not[health_status]=onTrack',
].join('&');
