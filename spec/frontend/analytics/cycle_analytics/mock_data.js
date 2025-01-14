import valueStreamAnalyticsStages from 'test_fixtures/projects/analytics/value_stream_analytics/stages.json';
import issueStageFixtures from 'test_fixtures/projects/analytics/value_stream_analytics/events/issue.json';
import planStageFixtures from 'test_fixtures/projects/analytics/value_stream_analytics/events/plan.json';
import reviewStageFixtures from 'test_fixtures/projects/analytics/value_stream_analytics/events/review.json';
import codeStageFixtures from 'test_fixtures/projects/analytics/value_stream_analytics/events/code.json';
import testStageFixtures from 'test_fixtures/projects/analytics/value_stream_analytics/events/test.json';
import stagingStageFixtures from 'test_fixtures/projects/analytics/value_stream_analytics/events/staging.json';

import { TEST_HOST } from 'helpers/test_constants';
import {
  DEFAULT_VALUE_STREAM,
  PAGINATION_TYPE,
  PAGINATION_SORT_DIRECTION_DESC,
  PAGINATION_SORT_FIELD_DURATION,
} from '~/analytics/cycle_analytics/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDateInPast } from '~/lib/utils/datetime_utility';

const DEFAULT_DAYS_IN_PAST = 30;
export const createdBefore = new Date(2019, 0, 14);
export const createdAfter = getDateInPast(createdBefore, DEFAULT_DAYS_IN_PAST);

export const deepCamelCase = (obj) => convertObjectPropsToCamelCase(obj, { deep: true });

export const getStageByTitle = (stages, title) =>
  stages.find((stage) => stage.title && stage.title.toLowerCase().trim() === title) || {};

export const defaultStages = ['issue', 'plan', 'review', 'code', 'test', 'staging'];

const stageFixtures = {
  issue: issueStageFixtures,
  plan: planStageFixtures,
  review: reviewStageFixtures,
  code: codeStageFixtures,
  test: testStageFixtures,
  staging: stagingStageFixtures,
};

export const summary = [
  { value: '20', title: 'New issues' },
  { value: null, title: 'Commits' },
  { value: null, title: 'Deploys' },
  { value: null, title: 'Deployment frequency', unit: '/day' },
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
  emptyStageText:
    'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.',

  slug: 'issue',
};

export const convertedData = {
  summary: [
    { value: '20', title: 'New issues' },
    { value: '-', title: 'Commits' },
    { value: '-', title: 'Deploys' },
    { value: '-', title: 'Deployment frequency', unit: '/day' },
  ],
};

export const rawIssueEvents = stageFixtures.issue;
export const issueEvents = deepCamelCase(rawIssueEvents);
export const reviewEvents = deepCamelCase(stageFixtures.review);

export const pathNavIssueMetric = 172800;

export const rawStageCounts = [
  { id: 'issue', count: 6 },
  { id: 'plan', count: 6 },
  { id: 'code', count: 1 },
  { id: 'test', count: 5 },
  { id: 'review', count: 12 },
  { id: 'staging', count: 3 },
];

export const stageCounts = {
  code: 1,
  issue: 6,
  plan: 6,
  review: 12,
  staging: 3,
  test: 5,
};

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
  issue: '2 days',
  plan: '1 day',
  review: '1 week',
  code: '1 day',
  test: '3 days',
  staging: '4 days',
};

export const allowedStages = [issueStage, planStage, codeStage];

export const transformedProjectStagePathData = [
  {
    metric: 172800,
    selected: true,
    stageCount: 6,
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
    stageCount: 6,
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
    stageCount: 1,
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
  full_path: 'groups/foo',
  avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
};

export const currentGroup = convertObjectPropsToCamelCase(group, { deep: true });
export const groupNamespace = {
  id: currentGroup.id,
  restApiRequestPath: `groups/${currentGroup.path}`,
  path: currentGroup.path,
  type: 'Group',
};

export const projectNamespace = {
  restApiRequestPath: 'some/cool/path',
  path: 'some/cool/path',
  type: 'Project',
};

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

export const rawValueStreamStages = valueStreamAnalyticsStages.stages;

export const valueStreamStages = rawValueStreamStages.map((s) =>
  convertObjectPropsToCamelCase(s, { deep: true }),
);

export const initialPaginationQuery = {
  page: 15,
  sort: PAGINATION_SORT_FIELD_DURATION,
  direction: PAGINATION_SORT_DIRECTION_DESC,
};

export const initialPaginationState = {
  ...initialPaginationQuery,
  page: null,
  hasNextPage: false,
};

export const basePaginationResult = {
  pagination: PAGINATION_TYPE,
  sort: PAGINATION_SORT_FIELD_DURATION,
  direction: PAGINATION_SORT_DIRECTION_DESC,
  page: null,
};

export const predefinedDateRange = 'last_week';
