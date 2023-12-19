import createMockApollo from 'helpers/mock_apollo_helper';
import draftStateQuery from '../../queries/states/draft.query.graphql';
import removeDraftMutation from '../../queries/toggle_draft.mutation.graphql';
import Draft from './draft.vue';

const defaultRender = ({ apolloProvider, check, mr }) => ({
  components: { Draft },
  apolloProvider,
  data() {
    return { mr, check };
  },
  template: '<draft :check="check" :mr="mr" />',
});

const Template = ({ userPermissionUpdateMergeRequest }) => {
  const requestHandlers = [
    [
      draftStateQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: '1',
              mergeRequest: {
                draft: false,
                id: '2',
                title: 'MR title',
                mergeableDiscussionsState: true,
                userPermissions: {
                  updateMergeRequest: userPermissionUpdateMergeRequest,
                },
              },
            },
          },
        }),
    ],
    [
      removeDraftMutation,
      () =>
        Promise.resolve({
          data: {
            mergeRequestSetDraft: {
              mergeRequest: {
                draft: false,
                id: '2',
                title: 'MR title',
                mergeableDiscussionsState: true,
              },
              errors: [],
            },
          },
        }),
    ],
  ];
  const apolloProvider = createMockApollo(requestHandlers);

  return defaultRender({
    apolloProvider,
    check: {
      identifier: 'draft_status',
      status: 'FAILED',
    },
  });
};

export const Default = Template.bind({});
Default.args = {
  userPermissionUpdateMergeRequest: true,
};

export default {
  title: 'vue_merge_request_widget/merge_checks/draft',
  component: Draft,
};
