import VueApollo from 'vue-apollo';
import { GlFormTextarea, GlFormInput, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { objectToQuery, redirectTo } from '~/lib/utils/url_utility';
import CommitForm from '~/pipeline_editor/components/commit/commit_form.vue';
import CommitSection from '~/pipeline_editor/components/commit/commit_section.vue';
import {
  COMMIT_ACTION_CREATE,
  COMMIT_ACTION_UPDATE,
  COMMIT_SUCCESS,
} from '~/pipeline_editor/constants';
import commitCreate from '~/pipeline_editor/graphql/mutations/commit_ci_file.mutation.graphql';
import updatePipelineEtag from '~/pipeline_editor/graphql/mutations/client/update_pipeline_etag.mutation.graphql';

import {
  mockCiConfigPath,
  mockCiYml,
  mockCommitCreateResponse,
  mockCommitCreateResponseNewEtag,
  mockCommitSha,
  mockCommitMessage,
  mockDefaultBranch,
  mockProjectFullPath,
  mockNewMergeRequestPath,
} from '../../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  refreshCurrentPage: jest.fn(),
  objectToQuery: jest.requireActual('~/lib/utils/url_utility').objectToQuery,
  mergeUrlParams: jest.requireActual('~/lib/utils/url_utility').mergeUrlParams,
}));

const mockVariables = {
  action: COMMIT_ACTION_UPDATE,
  projectPath: mockProjectFullPath,
  startBranch: mockDefaultBranch,
  message: mockCommitMessage,
  filePath: mockCiConfigPath,
  content: mockCiYml,
  lastCommitId: mockCommitSha,
};

const mockProvide = {
  ciConfigPath: mockCiConfigPath,
  projectFullPath: mockProjectFullPath,
  newMergeRequestPath: mockNewMergeRequestPath,
};

describe('Pipeline Editor | Commit section', () => {
  let wrapper;
  let mockApollo;
  const mockMutateCommitData = jest.fn();

  const defaultProps = {
    ciFileContent: mockCiYml,
    commitSha: mockCommitSha,
    isNewCiConfigFile: false,
  };

  const createComponent = ({ apolloConfig = {}, props = {}, options = {}, provide = {} } = {}) => {
    wrapper = mount(CommitSection, {
      propsData: { ...defaultProps, ...props },
      provide: { ...mockProvide, ...provide },
      data() {
        return {
          currentBranch: mockDefaultBranch,
        };
      },
      attachTo: document.body,
      ...apolloConfig,
      ...options,
    });
  };

  const createComponentWithApollo = (options) => {
    const handlers = [[commitCreate, mockMutateCommitData]];
    Vue.use(VueApollo);
    mockApollo = createMockApollo(handlers);

    const apolloConfig = {
      apolloProvider: mockApollo,
    };

    createComponent({ ...options, apolloConfig });
  };

  const findCommitForm = () => wrapper.findComponent(CommitForm);
  const findCommitBtnLoadingIcon = () =>
    wrapper.find('[type="submit"]').findComponent(GlLoadingIcon);

  const submitCommit = async ({
    message = mockCommitMessage,
    branch = mockDefaultBranch,
    openMergeRequest = false,
  } = {}) => {
    await findCommitForm().findComponent(GlFormTextarea).setValue(message);
    await findCommitForm().findComponent(GlFormInput).setValue(branch);
    if (openMergeRequest) {
      await findCommitForm().find('[data-testid="new-mr-checkbox"]').setChecked(openMergeRequest);
    }
    await findCommitForm().find('[type="submit"]').trigger('click');
    await waitForPromises();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the user commits a new file', () => {
    beforeEach(async () => {
      mockMutateCommitData.mockResolvedValue(mockCommitCreateResponse);
      createComponentWithApollo({ props: { isNewCiConfigFile: true } });
      await submitCommit();
    });

    it('calls the mutation with the CREATE action', () => {
      expect(mockMutateCommitData).toHaveBeenCalledTimes(1);
      expect(mockMutateCommitData).toHaveBeenCalledWith({
        ...mockVariables,
        action: COMMIT_ACTION_CREATE,
        branch: mockDefaultBranch,
      });
    });
  });

  describe('when the user commits an update to an existing file', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await submitCommit();
    });

    it('calls the mutation with the UPDATE action', () => {
      expect(mockMutateCommitData).toHaveBeenCalledTimes(1);
      expect(mockMutateCommitData).toHaveBeenCalledWith({
        ...mockVariables,
        action: COMMIT_ACTION_UPDATE,
        branch: mockDefaultBranch,
      });
    });
  });

  describe('when the user commits changes to the current branch', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await submitCommit();
    });

    it('calls the mutation with the current branch', () => {
      expect(mockMutateCommitData).toHaveBeenCalledTimes(1);
      expect(mockMutateCommitData).toHaveBeenCalledWith({
        ...mockVariables,
        branch: mockDefaultBranch,
      });
    });

    it('emits an event to communicate the commit was successful', () => {
      expect(wrapper.emitted('commit')).toHaveLength(1);
      expect(wrapper.emitted('commit')[0]).toEqual([{ type: COMMIT_SUCCESS }]);
    });

    it('emits an event to refetch the commit sha', () => {
      expect(wrapper.emitted('updateCommitSha')).toHaveLength(1);
    });

    it('shows no saving state', () => {
      expect(findCommitBtnLoadingIcon().exists()).toBe(false);
    });

    it('a second commit submits the latest sha, keeping the form updated', async () => {
      await submitCommit();

      expect(mockMutateCommitData).toHaveBeenCalledTimes(2);
      expect(mockMutateCommitData).toHaveBeenCalledWith({
        ...mockVariables,
        branch: mockDefaultBranch,
      });
    });
  });

  describe('when the user commits changes to a new branch', () => {
    const newBranch = 'new-branch';

    beforeEach(async () => {
      createComponentWithApollo();
      await submitCommit({
        branch: newBranch,
      });
    });

    it('calls the mutation with the new branch', () => {
      expect(mockMutateCommitData).toHaveBeenCalledWith({
        ...mockVariables,
        branch: newBranch,
      });
    });

    it('does not emit an event to refetch the commit sha', () => {
      expect(wrapper.emitted('updateCommitSha')).toBeUndefined();
    });
  });

  describe('when the user commits changes to open a new merge request', () => {
    const newBranch = 'new-branch';

    beforeEach(async () => {
      createComponentWithApollo();
      await submitCommit({
        branch: newBranch,
        openMergeRequest: true,
      });
    });

    it('redirects to the merge request page with source and target branches', () => {
      const branchesQuery = objectToQuery({
        'merge_request[source_branch]': newBranch,
        'merge_request[target_branch]': mockDefaultBranch,
      });

      expect(redirectTo).toHaveBeenCalledWith(`${mockNewMergeRequestPath}?${branchesQuery}`);
    });
  });

  describe('when the commit is ocurring', () => {
    beforeEach(() => {
      createComponentWithApollo();
    });

    it('shows a saving state', async () => {
      mockMutateCommitData.mockImplementationOnce(() => {
        expect(findCommitBtnLoadingIcon().exists()).toBe(true);
        return Promise.resolve();
      });

      await submitCommit({
        message: mockCommitMessage,
        branch: mockDefaultBranch,
        openMergeRequest: false,
      });
    });
  });

  describe('when the commit returns a different etag path', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      jest.spyOn(wrapper.vm.$apollo, 'mutate');
      mockMutateCommitData.mockResolvedValue(mockCommitCreateResponseNewEtag);
      await submitCommit();
    });

    it('calls the client mutation to update the etag', () => {
      // 1:Commit submission, 2:etag update, 3:currentBranch update, 4:lastCommit update
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(4);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenNthCalledWith(2, {
        mutation: updatePipelineEtag,
        variables: {
          pipelineEtag: mockCommitCreateResponseNewEtag.data.commitCreate.commitPipelinePath,
        },
      });
    });
  });

  it('sets listeners on commit form', () => {
    const handler = jest.fn();
    createComponent({ options: { listeners: { event: handler } } });
    findCommitForm().vm.$emit('event');
    expect(handler).toHaveBeenCalled();
  });

  it('passes down scroll-to-commit-form prop to commit form', () => {
    createComponent({ props: { 'scroll-to-commit-form': true } });
    expect(findCommitForm().props('scrollToCommitForm')).toBe(true);
  });
});
