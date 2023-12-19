import createMockApollo from 'helpers/mock_apollo_helper';
import rebaseStateQuery from '../../queries/states/rebase.query.graphql';
import Rebase from './rebase.vue';

const service = {
  rebase: () => new Promise(() => {}),
};

const defaultRender = ({ apolloProvider, check, mr, canCreatePipelineInTargetProject }) => ({
  components: { Rebase },
  apolloProvider,
  provide: {
    canCreatePipelineInTargetProject,
  },
  data() {
    return { service, mr: { ...mr, targetProjectFullPath: 'gitlab-org/gitlab' }, check };
  },
  template: '<rebase :mr="mr" :service="service" :check="check" />',
});

const Template = ({
  failed,
  pushToSourceBranch,
  rebaseInProgress,
  onlyAllowMergeIfPipelineSucceeds,
  canCreatePipelineInTargetProject,
}) => {
  const requestHandlers = [
    [
      rebaseStateQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: '1',
              mergeRequest: {
                id: '2',
                rebaseInProgress,
                targetBranch: 'main',
                userPermissions: {
                  pushToSourceBranch,
                },
                pipelines: {
                  nodes: [
                    {
                      id: '1',
                      project: {
                        id: '2',
                        fullPath: 'gitlab/gitlab',
                      },
                    },
                  ],
                },
              },
            },
          },
        }),
    ],
  ];
  const apolloProvider = createMockApollo(requestHandlers);

  return defaultRender({
    apolloProvider,
    check: {
      identifier: 'need_rebase',
      status: failed ? 'FAILED' : 'SUCCESS',
    },
    mr: { onlyAllowMergeIfPipelineSucceeds },
    canCreatePipelineInTargetProject,
  });
};

export const Default = Template.bind({});
Default.args = {
  failed: true,
  pushToSourceBranch: true,
  rebaseInProgress: false,
  onlyAllowMergeIfPipelineSucceeds: false,
  canCreatePipelineInTargetProject: false,
};

export default {
  title: 'vue_merge_request_widget/merge_checks/rebase',
  component: Rebase,
};
