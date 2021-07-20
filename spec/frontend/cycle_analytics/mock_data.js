import { TEST_HOST } from 'helpers/test_constants';
import { DEFAULT_VALUE_STREAM, DEFAULT_DAYS_IN_PAST } from '~/cycle_analytics/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDateInPast } from '~/lib/utils/datetime_utility';

export const createdBefore = new Date(2019, 0, 14);
export const createdAfter = getDateInPast(createdBefore, DEFAULT_DAYS_IN_PAST);

export const getStageByTitle = (stages, title) =>
  stages.find((stage) => stage.title && stage.title.toLowerCase().trim() === title) || {};

export const defaultStages = ['issue', 'plan', 'review', 'code', 'test', 'staging'];

export const summary = [
  { value: '20', title: 'New Issues' },
  { value: null, title: 'Commits' },
  { value: null, title: 'Deploys' },
  { value: null, title: 'Deployment Frequency', unit: 'per day' },
];

export const issueStage = {
  id: 'issue',
  title: 'Issue',
  name: 'issue',
  legend: '',
  description: 'Time before an issue gets scheduled',
  value: null,
};

export const planStage = {
  id: 'plan',
  title: 'Plan',
  name: 'plan',
  legend: '',
  description: 'Time before an issue starts implementation',
  value: 75600,
};

export const codeStage = {
  id: 'code',
  title: 'Code',
  name: 'code',
  legend: '',
  description: 'Time until first merge request',
  value: 172800,
};

export const testStage = {
  id: 'test',
  title: 'Test',
  name: 'test',
  legend: '',
  description: 'Total test time for all commits/merges',
  value: 17550,
};

export const reviewStage = {
  id: 'review',
  title: 'Review',
  name: 'review',
  legend: '',
  description: 'Time between merge request creation and merge/close',
  value: null,
};

export const stagingStage = {
  id: 'staging',
  title: 'Staging',
  name: 'staging',
  legend: '',
  description: 'From merge request merge until deploy to production',
  value: 172800,
};

export const selectedStage = {
  ...issueStage,
  value: null,
  active: false,
  isUserAllowed: true,
  emptyStageText:
    'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.',

  slug: 'issue',
};

export const stats = [issueStage, planStage, codeStage, testStage, reviewStage, stagingStage];

export const permissions = {
  issue: true,
  plan: true,
  code: true,
  test: true,
  review: true,
  staging: true,
};

export const rawData = {
  summary,
  stats,
  permissions,
};

export const convertedData = {
  summary: [
    { value: '20', title: 'New Issues' },
    { value: '-', title: 'Commits' },
    { value: '-', title: 'Deploys' },
    { value: '-', title: 'Deployment Frequency', unit: 'per day' },
  ],
};

export const rawEvents = [
  {
    title: 'Brockfunc-1617160796',
    author: {
      id: 275,
      name: 'VSM User4',
      username: 'vsm-user-4-1617160796',
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/6a6f5480ae582ba68982a34169420747?s=80&d=identicon',
      web_url: 'http://gdk.test:3001/vsm-user-4-1617160796',
      show_status: false,
      path: '/vsm-user-4-1617160796',
    },
    iid: '16',
    total_time: { days: 1, hours: 9 },
    created_at: 'about 1 month ago',
    url: 'http://gdk.test:3001/vsa-life/ror-project-vsa/-/issues/16',
    short_sha: 'some_sha',
    commit_url: 'some_commit_url',
  },
  {
    title: 'Subpod-1617160796',
    author: {
      id: 274,
      name: 'VSM User3',
      username: 'vsm-user-3-1617160796',
      state: 'active',
      avatar_url:
        'https://www.gravatar.com/avatar/fde853fc3ab7dc552e649dcb4fcf5f7f?s=80&d=identicon',
      web_url: 'http://gdk.test:3001/vsm-user-3-1617160796',
      show_status: false,
      path: '/vsm-user-3-1617160796',
    },
    iid: '20',
    total_time: { days: 2, hours: 18 },
    created_at: 'about 1 month ago',
    url: 'http://gdk.test:3001/vsa-life/ror-project-vsa/-/issues/20',
  },
];

export const convertedEvents = rawEvents.map((ev) =>
  convertObjectPropsToCamelCase(ev, { deep: true }),
);

export const pathNavIssueMetric = 172800;

export const rawStageMedians = [
  { id: 'issue', value: 172800 },
  { id: 'plan', value: 86400 },
  { id: 'review', value: 1036800 },
  { id: 'code', value: 129600 },
  { id: 'test', value: 259200 },
  { id: 'staging', value: 388800 },
];

export const stageMedians = {
  issue: 172800,
  plan: 86400,
  review: 1036800,
  code: 129600,
  test: 259200,
  staging: 388800,
};

export const formattedStageMedians = {
  issue: '2d',
  plan: '1d',
  review: '1w',
  code: '1d',
  test: '3d',
  staging: '4d',
};

export const allowedStages = [issueStage, planStage, codeStage];

export const transformedProjectStagePathData = [
  {
    metric: 172800,
    selected: true,
    stageCount: undefined,
    icon: null,
    id: 'issue',
    title: 'Issue',
    name: 'issue',
    legend: '',
    description: 'Time before an issue gets scheduled',
    value: null,
  },
  {
    metric: 86400,
    selected: false,
    stageCount: undefined,
    icon: null,
    id: 'plan',
    title: 'Plan',
    name: 'plan',
    legend: '',
    description: 'Time before an issue starts implementation',
    value: 75600,
  },
  {
    metric: 129600,
    selected: false,
    stageCount: undefined,
    icon: null,
    id: 'code',
    title: 'Code',
    name: 'code',
    legend: '',
    description: 'Time until first merge request',
    value: 172800,
  },
];

export const selectedValueStream = DEFAULT_VALUE_STREAM;

export const group = {
  id: 1,
  name: 'foo',
  path: 'foo',
  full_path: 'foo',
  avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
};

export const currentGroup = convertObjectPropsToCamelCase(group, { deep: true });

export const selectedProjects = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'cool project',
    pathWithNamespace: 'group/cool-project',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'another cool project',
    pathWithNamespace: 'group/another-cool-project',
    avatarUrl: null,
  },
];

export const rawValueStreamStages = [
  {
    title: 'Issue',
    hidden: false,
    legend: '',
    description: 'Time before an issue gets scheduled',
    id: 'issue',
    custom: false,
    start_event_html_description:
      '\u003cp data-sourcepos="1:1-1:13" dir="auto"\u003eIssue created\u003c/p\u003e',
    end_event_html_description:
      '\u003cp data-sourcepos="1:1-1:71" dir="auto"\u003eIssue first associated with a milestone or issue first added to a board\u003c/p\u003e',
  },
  {
    title: 'Plan',
    hidden: false,
    legend: '',
    description: 'Time before an issue starts implementation',
    id: 'plan',
    custom: false,
    start_event_html_description:
      '\u003cp data-sourcepos="1:1-1:71" dir="auto"\u003eIssue first associated with a milestone or issue first added to a board\u003c/p\u003e',
    end_event_html_description:
      '\u003cp data-sourcepos="1:1-1:33" dir="auto"\u003eIssue first mentioned in a commit\u003c/p\u003e',
  },
  {
    title: 'Code',
    hidden: false,
    legend: '',
    description: 'Time until first merge request',
    id: 'code',
    custom: false,
    start_event_html_description:
      '\u003cp data-sourcepos="1:1-1:33" dir="auto"\u003eIssue first mentioned in a commit\u003c/p\u003e',
    end_event_html_description:
      '\u003cp data-sourcepos="1:1-1:21" dir="auto"\u003eMerge request created\u003c/p\u003e',
  },
];

export const valueStreamStages = rawValueStreamStages.map((s) =>
  convertObjectPropsToCamelCase(s, { deep: true }),
);

// Temporary workaronud until we have relevant backend fixtures endpoints
export const testEvents = [
  {
    name: 'test',
    id: 53,
    branch: {
      name: 'master',
      url: 'http://localhost/group3/project9/-/tree/master',
    },
    shortSha: 'b83d6e39',
    author: {
      id: 18,
      name: 'John Doe21',
      username: 'user12',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/70a85d1042e02066f7451ae831689be0?s=80&d=identicon',
      webUrl: 'http://localhost/user12',
      showStatus: false,
      path: '/user12',
    },
    date: 'about 1 hour ago',
    totalTime: { mins: 2 },
    url: 'http://localhost/group3/project9/-/jobs/53',
    commitUrl: 'http://localhost/group3/project9/-/commit/b83d6e391c22777fca1ed3012fce84f633d7fed0',
  },
  {
    name: 'test',
    id: 54,
    branch: {
      name: 'master',
      url: 'http://localhost/group3/project9/-/tree/master',
    },
    shortSha: 'b83d6e39',
    author: {
      id: 18,
      name: 'John Doe21',
      username: 'user12',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/70a85d1042e02066f7451ae831689be0?s=80&d=identicon',
      webUrl: 'http://localhost/user12',
      showStatus: false,
      path: '/user12',
    },
    date: 'about 1 hour ago',
    totalTime: { mins: 2 },
    url: 'http://localhost/group3/project9/-/jobs/54',
    commitUrl: 'http://localhost/group3/project9/-/commit/b83d6e391c22777fca1ed3012fce84f633d7fed0',
  },
];

export const stagingEvents = [
  {
    name: 'test',
    id: 83,
    branch: {
      name: 'master',
      url: 'http://localhost/group3/project9/-/tree/master',
    },
    shortSha: 'b83d6e39',
    author: {
      id: 18,
      name: 'John Doe21',
      username: 'user12',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/70a85d1042e02066f7451ae831689be0?s=80&d=identicon',
      webUrl: 'http://localhost/user12',
      showStatus: false,
      path: '/user12',
    },
    date: 'about 1 hour ago',
    totalTime: { mins: 2 },
    url: 'http://localhost/group3/project9/-/jobs/83',
    commitUrl: 'http://localhost/group3/project9/-/commit/b83d6e391c22777fca1ed3012fce84f633d7fed0',
  },
  {
    name: 'test',
    id: 84,
    branch: {
      name: 'master',
      url: 'http://localhost/group3/project9/-/tree/master',
    },
    shortSha: 'b83d6e39',
    author: {
      id: 18,
      name: 'John Doe21',
      username: 'user12',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/70a85d1042e02066f7451ae831689be0?s=80&d=identicon',
      webUrl: 'http://localhost/user12',
      showStatus: false,
      path: '/user12',
    },
    date: 'about 1 hour ago',
    totalTime: { mins: 2 },
    url: 'http://localhost/group3/project9/-/jobs/84',
    commitUrl: 'http://localhost/group3/project9/-/commit/b83d6e391c22777fca1ed3012fce84f633d7fed0',
  },
];

export const reviewEvents = [
  {
    title: 'My title 98',
    author: {
      id: 17,
      name: 'John Doe20',
      username: 'user11',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/fb32cf62136a195ec4f40ec6d1cfffdc?s=80&d=identicon',
      webUrl: 'http://localhost/user11',
      showStatus: false,
      path: '/user11',
    },
    iid: '3',
    totalTime: { days: 15 },
    createdAt: '20 days ago',
    url: 'http://localhost/group3/project9/-/merge_requests/3',
    state: 'opened',
  },
  {
    title: 'My title 99',
    author: {
      id: 17,
      name: 'John Doe20',
      username: 'user11',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/fb32cf62136a195ec4f40ec6d1cfffdc?s=80&d=identicon',
      webUrl: 'http://localhost/user11',
      showStatus: false,
      path: '/user11',
    },
    iid: '4',
    totalTime: { days: 9 },
    createdAt: '19 days ago',
    url: 'http://localhost/group3/project9/-/merge_requests/4',
    state: 'opened',
  },
];

export const issueEvents = [
  {
    title: 'My title 24',
    author: {
      id: 17,
      name: 'John Doe20',
      username: 'user11',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/fb32cf62136a195ec4f40ec6d1cfffdc?s=80&d=identicon',
      webUrl: 'http://localhost/user11',
      showStatus: false,
      path: '/user11',
    },
    iid: '3',
    totalTime: { days: 2 },
    createdAt: '4 days ago',
    url: 'http://localhost/group3/project9/-/issues/3',
  },
  {
    title: 'My title 23',
    author: {
      id: 17,
      name: 'John Doe20',
      username: 'user11',
      state: 'active',
      avatarUrl:
        'https://www.gravatar.com/avatar/fb32cf62136a195ec4f40ec6d1cfffdc?s=80&d=identicon',
      webUrl: 'http://localhost/user11',
      showStatus: false,
      path: '/user11',
    },
    iid: '2',
    totalTime: { days: 2 },
    createdAt: '5 days ago',
    url: 'http://localhost/group3/project9/-/issues/2',
  },
];
