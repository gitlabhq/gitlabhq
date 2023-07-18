import VueApollo from 'vue-apollo';
import { GlFormTextarea, GlFormInput, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import CommitForm from '~/ci/pipeline_editor/components/commit/commit_form.vue';
import CommitSection from '~/ci/pipeline_editor/components/commit/commit_section.vue';
import {
  COMMIT_ACTION_CREATE,
  COMMIT_ACTION_UPDATE,
  COMMIT_SUCCESS,
  COMMIT_SUCCESS_WITH_REDIRECT,
  pipelineEditorTrackingOptions,
} from '~/ci/pipeline_editor/constants';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';
import commitCreate from '~/ci/pipeline_editor/graphql/mutations/commit_ci_file.mutation.graphql';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import getPipelineEtag from '~/ci/pipeline_editor/graphql/queries/client/pipeline_etag.query.graphql';

import {
  mockCiConfigPath,
  mockCiYml,
  mockCommitCreateResponse,
  mockCommitCreateResponseNewEtag,
  mockCommitSha,
  mockCommitMessage,
  mockDefaultBranch,
  mockProjectFullPath,
} from '../../mock_data';

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
};

describe('Pipeline Editor | Commit section', () => {
  let wrapper;
  let mockApollo;
  const mockMutateCommitData = jest.fn();

  const defaultProps = {
    ciFileContent: mockCiYml,
    commitSha: mockCommitSha,
    hasUnsavedChanges: true,
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
    mockApollo = createMockApollo(handlers, resolvers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getCurrentBranch,
      data: {
        workBranches: {
          __typename: 'BranchList',
          current: {
            __typename: 'WorkBranch',
            name: mockDefaultBranch,
          },
        },
      },
    });

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
      mockMutateCommitData.mockResolvedValue(mockCommitCreateResponse);
      createComponentWithApollo();
      mockMutateCommitData.mockResolvedValue(mockCommitCreateResponse);
      await submitCommit({
        branch: newBranch,
        openMergeRequest: true,
      });
    });

    it('emits a commit event with the right type, sourceBranch and targetBranch', () => {
      expect(wrapper.emitted('commit')).toHaveLength(1);
      expect(wrapper.emitted('commit')[0]).toMatchObject([
        {
          type: COMMIT_SUCCESS_WITH_REDIRECT,
          params: { sourceBranch: newBranch, targetBranch: mockDefaultBranch },
        },
      ]);
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
      jest.spyOn(mockApollo.clients.defaultClient.cache, 'writeQuery');

      mockMutateCommitData.mockResolvedValue(mockCommitCreateResponseNewEtag);
      await submitCommit();
    });

    it('calls the client mutation to update the etag in the cache', () => {
      expect(mockApollo.clients.defaultClient.cache.writeQuery).toHaveBeenCalledWith({
        query: getPipelineEtag,
        data: {
          etags: {
            __typename: 'EtagValues',
            pipeline: mockCommitCreateResponseNewEtag.data.commitCreate.commitPipelinePath,
          },
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

  describe('tracking', () => {
    let trackingSpy;
    const { actions, label } = pipelineEditorTrackingOptions;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    describe('when user commit a new file', () => {
      beforeEach(async () => {
        mockMutateCommitData.mockResolvedValue(mockCommitCreateResponse);
        createComponentWithApollo({ props: { isNewCiConfigFile: true } });
        await submitCommit();
      });

      it('calls tracking event with the CREATE property', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, actions.commitCiConfig, {
          label,
          property: COMMIT_ACTION_CREATE,
        });
      });
    });

    describe('when user commit an update to the CI file', () => {
      beforeEach(async () => {
        mockMutateCommitData.mockResolvedValue(mockCommitCreateResponse);
        createComponentWithApollo({ props: { isNewCiConfigFile: false } });
        await submitCommit();
      });

      it('calls the tracking event with the UPDATE property', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, actions.commitCiConfig, {
          label,
          property: COMMIT_ACTION_UPDATE,
        });
      });
    });
  });
});
