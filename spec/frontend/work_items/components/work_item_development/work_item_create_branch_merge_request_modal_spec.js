import Vue, { nextTick } from 'vue';
import { GlForm, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import WorkItemCreateBranchMergeRequestModal from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_modal.vue';
import getProjectRootRef from '~/work_items/graphql/get_project_root_ref.query.graphql';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('CreateBranchMergeRequestModal', () => {
  Vue.use(VueApollo);

  let wrapper;
  let mock;
  let mockApollo;

  const showToast = jest.fn();

  const projectRefHandler = jest.fn().mockResolvedValue({
    data: {
      project: {
        id: 'gid://gitlab/Project/2',
        repository: {
          rootRef: 'master',
          __typename: 'Repository',
        },
        __typename: 'Project',
      },
    },
  });

  const createWrapper = ({
    workItemId = 'gid://gitlab/WorkItem/1',
    workItemIid = '1',
    showBranchFlow = true,
    showMergeRequestFlow = false,
    showModal = true,
    workItemType = 'Issue',
    workItemFullPath = 'fullPath',
  } = {}) => {
    mockApollo = createMockApollo([[getProjectRootRef, projectRefHandler]]);

    wrapper = shallowMount(WorkItemCreateBranchMergeRequestModal, {
      apolloProvider: mockApollo,
      propsData: {
        workItemId,
        workItemIid,
        workItemType,
        showBranchFlow,
        showMergeRequestFlow,
        showModal,
        workItemFullPath,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const firePrimaryEvent = () => findGlModal().vm.$emit('primary', { preventDefault: jest.fn() });

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/fullPath/-/issues/1/can_create_branch').reply(HTTP_STATUS_OK, {
      can_create_branch: true,
      suggested_branch_name: 'suggested_branch_name',
    });
    return createWrapper();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('on initialise', () => {
    it('shows the form', () => {
      expect(findForm().exists()).toBe(true);
    });
  });

  describe('Branch creation', () => {
    it('calls the create branch mutation with the correct parameters', async () => {
      createWrapper();
      await waitForPromises();

      jest.spyOn(axios, 'post');
      mock
        .onPost(
          '/fullPath/-/branches?branch_name=suggested_branch_name&format=json&issue_iid=1&ref=defaultBranch',
        )
        .reply(200, { data: { url: 'http://test.com/branch' } });

      firePrimaryEvent();
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledWith(
        `/fullPath/-/branches?branch_name=suggested_branch_name&format=json&issue_iid=1&ref=master`,
        {
          confidential_issue_project_id: null,
        },
      );
    });

    it('shows a success toast message when branch is created', async () => {
      createWrapper();
      await waitForPromises();

      mock
        .onPost(
          '/fullPath/-/branches?branch_name=suggested_branch_name&format=json&issue_iid=1&ref=master',
        )
        .reply(200, { data: { url: 'http://test.com/branch' } });

      firePrimaryEvent();
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('Branch created.', {
        autoHideDelay: 10000,
        action: {
          text: 'View branch',
          onClick: expect.any(Function),
        },
      });
    });

    it('shows an error alert when branch creation fails', async () => {
      mock
        .onPost(
          '/fullPath/-/branches?branch_name=suggested_branch_name&format=json&issue_iid=1&ref=master',
        )
        .reply(422, { message: 'Error creating branch' });
      createWrapper();
      await waitForPromises();

      firePrimaryEvent();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to create a branch for this issue. Please try again.',
      });
    });
  });

  describe('Merge request creation', () => {
    it('redirects to the the create merge branch request url with the correct parameters', async () => {
      createWrapper({ showBranchFlow: false, showMergeRequestFlow: true });
      await waitForPromises();

      jest.spyOn(axios, 'post');
      mock
        .onPost(
          '/fullPath/-/branches?branch_name=suggested_branch_name&format=json&issue_iid=1&ref=master',
        )
        .reply(200, { data: { url: 'http://test.com/branch' } });

      firePrimaryEvent();
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledWith(
        `/fullPath/-/branches?branch_name=suggested_branch_name&format=json&issue_iid=1&ref=master`,
        {
          confidential_issue_project_id: null,
        },
      );

      await waitForPromises();

      await nextTick();

      expect(visitUrl).toHaveBeenCalledWith(
        '/fullPath/-/merge_requests/new?merge_request%5Bissue_iid%5D=1&merge_request%5Bsource_branch%5D=suggested_branch_name&merge_request%5Btarget_branch%5D=master',
      );
    });
  });
});
