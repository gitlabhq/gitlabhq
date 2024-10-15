import createMockApollo from 'helpers/mock_apollo_helper';
import mergeChecksQuery from '../queries/merge_checks.query.graphql';
import conflictsStateQuery from '../queries/states/conflicts.query.graphql';
import MergeChecks from './merge_checks.vue';

const stylesheetsRequireCtx = require.context(
  '../../../stylesheets',
  true,
  /(page_bundles\/merge_requests)\.scss$/,
);

stylesheetsRequireCtx('./page_bundles/merge_requests.scss');

const defaultRender = (apolloProvider) => ({
  components: { MergeChecks },
  apolloProvider,
  data() {
    return { service: {}, mr: { conflictResolutionPath: 'https://gitlab.com' } };
  },
  template: '<merge-checks :mr="mr" :service="service" />',
});

const Template = ({ canMerge, failed, checking, pushToSourceBranch }) => {
  const requestHandlers = [
    [
      mergeChecksQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                userPermissions: { canMerge },
                mergeabilityChecks: [
                  {
                    identifier: 'DISCUSSIONS_NOT_RESOLVED',
                    status: failed ? 'FAILED' : 'SUCCESS',
                  },
                  {
                    identifier: 'CONFLICT',
                    status: failed ? 'FAILED' : 'SUCCESS',
                  },
                  {
                    identifier: 'NOT_APPROVED',
                    status: checking ? 'CHECKING' : 'SUCCESS',
                  },
                ],
              },
            },
          },
        }),
    ],
    [
      conflictsStateQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                shouldBeRebased: false,
                sourceBranchProtected: false,
                userPermissions: { pushToSourceBranch },
              },
            },
          },
        }),
    ],
  ];
  const apolloProvider = createMockApollo(requestHandlers);

  return defaultRender(apolloProvider);
};

const LoadingTemplate = () => {
  const requestHandlers = [[mergeChecksQuery, () => new Promise(() => {})]];
  const apolloProvider = createMockApollo(requestHandlers);

  return defaultRender(apolloProvider);
};

export const Default = Template.bind({});
Default.args = { canMerge: true, failed: true, checking: false, pushToSourceBranch: true };

export const Loading = LoadingTemplate.bind({});
Loading.args = {};

export default {
  title: 'vue_merge_request_widget/merge_checks',
  component: MergeChecks,
};
