import { formatStages } from '~/projects/commit_box/info/utils';

const graphqlStage = [
  {
    __typename: 'CiStage',
    name: 'deploy',
    detailedStatus: {
      __typename: 'DetailedStatus',
      icon: 'status_success',
      group: 'success',
      id: 'success-409-409',
    },
  },
];

const restStage = [
  {
    name: 'deploy',
    title: 'deploy: passed',
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      tooltip: 'passed',
      has_details: true,
      details_path: '/root/ci-project/-/pipelines/318#deploy',
      illustration: null,
      favicon:
        '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
    },
    path: '/root/ci-project/-/pipelines/318#deploy',
    dropdown_path: '/root/ci-project/-/pipelines/318/stage.json?stage=deploy',
  },
];

describe('Utils', () => {
  it('combines REST and GraphQL stages correctly for component', () => {
    expect(formatStages(graphqlStage, restStage)).toEqual([
      {
        dropdown_path: '/root/ci-project/-/pipelines/318/stage.json?stage=deploy',
        name: 'deploy',
        status: {
          __typename: 'DetailedStatus',
          group: 'success',
          icon: 'status_success',
          id: 'success-409-409',
        },
        title: 'deploy: passed',
      },
    ]);
  });

  it('throws an error if arrays are not the same length', () => {
    expect(() => {
      formatStages(graphqlStage, []);
    }).toThrow('Rest stages and graphQl stages must be the same length');
  });
});
