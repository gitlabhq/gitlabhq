import Vue from 'vue';
import VueApollo from 'vue-apollo';

import getStateQueryResponse from 'test_fixtures/graphql/merge_requests/get_state.query.graphql.json';

import { createAlert } from '~/alert';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import MergeRequest from '~/merge_request';

import DraftCheck from '~/vue_merge_request_widget/components/checks/draft.vue';
import {
  DRAFT_CHECK_READY,
  DRAFT_CHECK_ERROR,
} from '~/vue_merge_request_widget/components/checks/i18n';
import { FAILURE_REASONS } from '~/vue_merge_request_widget/components/checks/constants';

import draftQuery from '~/vue_merge_request_widget/queries/states/draft.query.graphql';
import getStateQuery from '~/vue_merge_request_widget/queries/get_state.query.graphql';
import removeDraftMutation from '~/vue_merge_request_widget/queries/toggle_draft.mutation.graphql';

Vue.use(VueApollo);

const TEST_PROJECT_ID = getStateQueryResponse.data.project.id;
const TEST_MR_ID = getStateQueryResponse.data.project.mergeRequest.id;
const TEST_MR_IID = '23';
const TEST_MR_TITLE = 'Test MR Title';
const TEST_PROJECT_PATH = 'lorem/ipsum';

jest.mock('~/alert');
jest.mock('~/merge_request', () => ({ toggleDraftStatus: jest.fn() }));

describe('~/vue_merge_request_widget/components/checks/draft.vue', () => {
  let wrapper;
  let apolloProvider;

  let draftQuerySpy;
  let removeDraftMutationSpy;

  const findMarkReadyButton = () => wrapper.findByTestId('mark-as-ready-button');

  const createDraftQueryResponse = (canUpdateMergeRequest) => ({
    data: {
      project: {
        __typename: 'Project',
        id: TEST_PROJECT_ID,
        mergeRequest: {
          __typename: 'MergeRequest',
          id: TEST_MR_ID,
          draft: true,
          title: TEST_MR_TITLE,
          mergeableDiscussionsState: false,
          userPermissions: {
            updateMergeRequest: canUpdateMergeRequest,
          },
        },
      },
    },
  });
  const createRemoveDraftMutationResponse = () => ({
    data: {
      mergeRequestSetDraft: {
        __typename: 'MergeRequestSetWipPayload',
        errors: [],
        mergeRequest: {
          __typename: 'MergeRequest',
          id: TEST_MR_ID,
          title: TEST_MR_TITLE,
          draft: false,
          mergeableDiscussionsState: true,
        },
      },
    },
  });

  const createComponent = async () => {
    wrapper = mountExtended(DraftCheck, {
      apolloProvider,
      propsData: {
        mr: {
          issuableId: TEST_MR_ID,
          title: TEST_MR_TITLE,
          iid: TEST_MR_IID,
          targetProjectFullPath: TEST_PROJECT_PATH,
        },
        check: {
          identifier: 'draft_status',
          status: 'FAILED',
        },
      },
    });

    await waitForPromises();

    // why: draft.vue has some coupling that this query has been read before
    //      for some reason this has to happen **after** the component has mounted
    //      or apollo throws errors.
    apolloProvider.defaultClient.cache.writeQuery({
      query: getStateQuery,
      variables: {
        projectPath: TEST_PROJECT_PATH,
        iid: TEST_MR_IID,
      },
      data: getStateQueryResponse.data,
    });
  };

  beforeEach(() => {
    draftQuerySpy = jest.fn().mockResolvedValue(createDraftQueryResponse(true));
    removeDraftMutationSpy = jest.fn().mockResolvedValue(createRemoveDraftMutationResponse());

    apolloProvider = createMockApollo([
      [draftQuery, draftQuerySpy],
      [removeDraftMutation, removeDraftMutationSpy],
    ]);
  });

  describe('when user can update MR', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders text', () => {
      const message = wrapper.text();
      expect(message).toContain(FAILURE_REASONS.draft_status);
    });

    it('renders mark ready button', () => {
      expect(findMarkReadyButton().text()).toBe(DRAFT_CHECK_READY);
    });

    it('does not call remove draft mutation', () => {
      expect(removeDraftMutationSpy).not.toHaveBeenCalled();
    });

    describe('when mark ready button is clicked', () => {
      beforeEach(async () => {
        findMarkReadyButton().vm.$emit('click');

        await waitForPromises();
      });

      it('calls mutation spy', () => {
        expect(removeDraftMutationSpy).toHaveBeenCalledWith({
          draft: false,
          iid: TEST_MR_IID,
          projectPath: TEST_PROJECT_PATH,
        });
      });

      it('does not create alert', () => {
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('calls toggleDraftStatus', () => {
        expect(MergeRequest.toggleDraftStatus).toHaveBeenCalledWith(TEST_MR_TITLE, true);
      });
    });

    describe('when mutation fails and ready button is clicked', () => {
      beforeEach(async () => {
        removeDraftMutationSpy.mockRejectedValue(new Error('TEST FAIL'));
        findMarkReadyButton().vm.$emit('click');

        await waitForPromises();
      });

      it('creates alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: DRAFT_CHECK_ERROR,
        });
      });

      it('does not call toggleDraftStatus', () => {
        expect(MergeRequest.toggleDraftStatus).not.toHaveBeenCalled();
      });
    });
  });

  describe('when user cannot update MR', () => {
    beforeEach(async () => {
      draftQuerySpy.mockResolvedValue(createDraftQueryResponse(false));

      createComponent();

      await waitForPromises();
    });

    it('does not render mark ready button', () => {
      expect(findMarkReadyButton().exists()).toBe(false);
    });
  });
});
