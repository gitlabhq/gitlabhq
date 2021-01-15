import { nextTick } from 'vue';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import { GlAlert, GlButton, GlFormInput, GlFormTextarea, GlLoadingIcon, GlTabs } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';

import httpStatusCodes from '~/lib/utils/http_status';
import { objectToQuery, redirectTo, refreshCurrentPage } from '~/lib/utils/url_utility';
import {
  mockCiConfigPath,
  mockCiConfigQueryResponse,
  mockCiYml,
  mockCommitSha,
  mockCommitNextSha,
  mockCommitMessage,
  mockDefaultBranch,
  mockProjectPath,
  mockProjectFullPath,
  mockProjectNamespace,
  mockNewMergeRequestPath,
} from './mock_data';

import CommitForm from '~/pipeline_editor/components/commit/commit_form.vue';
import getCiConfigData from '~/pipeline_editor/graphql/queries/ci_config.graphql';
import EditorTab from '~/pipeline_editor/components/ui/editor_tab.vue';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';
import TextEditor from '~/pipeline_editor/components/text_editor.vue';

const localVue = createLocalVue();
localVue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  refreshCurrentPage: jest.fn(),
  objectToQuery: jest.requireActual('~/lib/utils/url_utility').objectToQuery,
  mergeUrlParams: jest.requireActual('~/lib/utils/url_utility').mergeUrlParams,
}));

const MockEditorLite = {
  template: '<div/>',
};

const mockProvide = {
  projectFullPath: mockProjectFullPath,
  projectPath: mockProjectPath,
  projectNamespace: mockProjectNamespace,
  glFeatures: {
    ciConfigVisualizationTab: true,
  },
};

describe('~/pipeline_editor/pipeline_editor_app.vue', () => {
  let wrapper;

  let mockApollo;
  let mockBlobContentData;
  let mockCiConfigData;
  let mockMutate;

  const createComponent = ({
    props = {},
    blobLoading = false,
    lintLoading = false,
    options = {},
    mountFn = shallowMount,
    provide = mockProvide,
  } = {}) => {
    mockMutate = jest.fn().mockResolvedValue({
      data: {
        commitCreate: {
          errors: [],
          commit: {
            sha: mockCommitNextSha,
          },
        },
      },
    });

    wrapper = mountFn(PipelineEditorApp, {
      propsData: {
        ciConfigPath: mockCiConfigPath,
        commitSha: mockCommitSha,
        defaultBranch: mockDefaultBranch,
        newMergeRequestPath: mockNewMergeRequestPath,
        ...props,
      },
      provide,
      stubs: {
        GlTabs,
        GlButton,
        CommitForm,
        EditorLite: MockEditorLite,
        TextEditor,
      },
      mocks: {
        $apollo: {
          queries: {
            content: {
              loading: blobLoading,
            },
            ciConfigData: {
              loading: lintLoading,
            },
          },
          mutate: mockMutate,
        },
      },
      // attachTo is required for input/submit events
      attachTo: mountFn === mount ? document.body : null,
      ...options,
    });
  };

  const createComponentWithApollo = ({ props = {}, mountFn = shallowMount } = {}) => {
    const handlers = [[getCiConfigData, mockCiConfigData]];
    const resolvers = {
      Query: {
        blobContent() {
          return {
            __typename: 'BlobContent',
            rawData: mockBlobContentData(),
          };
        },
      },
    };

    mockApollo = createMockApollo(handlers, resolvers);

    const options = {
      localVue,
      mocks: {},
      apolloProvider: mockApollo,
    };

    createComponent({ props, options }, mountFn);
  };

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findAlert = () => wrapper.find(GlAlert);
  const findTabAt = (i) => wrapper.findAll(EditorTab).at(i);
  const findVisualizationTab = () => wrapper.find('[data-testid="visualization-tab"]');
  const findTextEditor = () => wrapper.find(TextEditor);
  const findEditorLite = () => wrapper.find(MockEditorLite);
  const findCommitForm = () => wrapper.find(CommitForm);
  const findPipelineGraph = () => wrapper.find(PipelineGraph);
  const findCommitBtnLoadingIcon = () => wrapper.find('[type="submit"]').find(GlLoadingIcon);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
    mockCiConfigData = jest.fn();
  });

  afterEach(() => {
    mockBlobContentData.mockReset();
    mockCiConfigData.mockReset();
    refreshCurrentPage.mockReset();
    redirectTo.mockReset();
    mockMutate.mockReset();

    wrapper.destroy();
    wrapper = null;
  });

  it('displays a loading icon if the blob query is loading', () => {
    createComponent({ blobLoading: true });

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findTextEditor().exists()).toBe(false);
  });

  describe('tabs', () => {
    describe('editor tab', () => {
      it('displays editor only after the tab is mounted', async () => {
        createComponent({ mountFn: mount });

        expect(findTabAt(0).find(TextEditor).exists()).toBe(false);

        await nextTick();

        expect(findTabAt(0).find(TextEditor).exists()).toBe(true);
      });
    });

    describe('visualization tab', () => {
      describe('with feature flag on', () => {
        beforeEach(() => {
          createComponent();
        });

        it('display the tab', () => {
          expect(findVisualizationTab().exists()).toBe(true);
        });

        it('displays a loading icon if the lint query is loading', () => {
          createComponent({ lintLoading: true });

          expect(findLoadingIcon().exists()).toBe(true);
          expect(findPipelineGraph().exists()).toBe(false);
        });
      });

      describe('with feature flag off', () => {
        beforeEach(() => {
          createComponent({
            provide: {
              ...mockProvide,
              glFeatures: { ciConfigVisualizationTab: false },
            },
          });
        });

        it('does not display the tab', () => {
          expect(findVisualizationTab().exists()).toBe(false);
        });
      });
    });
  });

  describe('when data is set', () => {
    beforeEach(async () => {
      createComponent({ mountFn: mount });

      wrapper.setData({
        content: mockCiYml,
        contentModel: mockCiYml,
      });

      await waitForPromises();
    });

    it('displays content after the query loads', () => {
      expect(findLoadingIcon().exists()).toBe(false);

      expect(findEditorLite().attributes('value')).toBe(mockCiYml);
      expect(findEditorLite().attributes('file-name')).toBe(mockCiConfigPath);
    });

    it('configures text editor', () => {
      expect(findTextEditor().props('commitSha')).toBe(mockCommitSha);
    });

    describe('commit form', () => {
      const mockVariables = {
        content: mockCiYml,
        filePath: mockCiConfigPath,
        lastCommitId: mockCommitSha,
        message: mockCommitMessage,
        projectPath: mockProjectFullPath,
        startBranch: mockDefaultBranch,
      };

      const findInForm = (selector) => findCommitForm().find(selector);

      const submitCommit = async ({
        message = mockCommitMessage,
        branch = mockDefaultBranch,
        openMergeRequest = false,
      } = {}) => {
        await findInForm(GlFormTextarea).setValue(message);
        await findInForm(GlFormInput).setValue(branch);
        if (openMergeRequest) {
          await findInForm('[data-testid="new-mr-checkbox"]').setChecked(openMergeRequest);
        }
        await findInForm('[type="submit"]').trigger('click');
      };

      const cancelCommitForm = async () => {
        const findCancelBtn = () => wrapper.find('[type="reset"]');
        await findCancelBtn().trigger('click');
      };

      describe('when the user commits changes to the current branch', () => {
        beforeEach(async () => {
          await submitCommit();
        });

        it('calls the mutation with the default branch', () => {
          expect(mockMutate).toHaveBeenCalledWith({
            mutation: expect.any(Object),
            variables: {
              ...mockVariables,
              branch: mockDefaultBranch,
            },
          });
        });

        it('displays an alert to indicate success', () => {
          expect(findAlert().text()).toMatchInterpolatedText(
            'Your changes have been successfully committed.',
          );
        });

        it('shows no saving state', () => {
          expect(findCommitBtnLoadingIcon().exists()).toBe(false);
        });

        it('a second commit submits the latest sha, keeping the form updated', async () => {
          await submitCommit();

          expect(mockMutate).toHaveBeenCalledTimes(2);
          expect(mockMutate).toHaveBeenLastCalledWith({
            mutation: expect.any(Object),
            variables: {
              ...mockVariables,
              lastCommitId: mockCommitNextSha,
              branch: mockDefaultBranch,
            },
          });
        });
      });

      describe('when the user commits changes to a new branch', () => {
        const newBranch = 'new-branch';

        beforeEach(async () => {
          await submitCommit({
            branch: newBranch,
          });
        });

        it('calls the mutation with the new branch', () => {
          expect(mockMutate).toHaveBeenCalledWith({
            mutation: expect.any(Object),
            variables: {
              ...mockVariables,
              branch: newBranch,
            },
          });
        });
      });

      describe('when the user commits changes to open a new merge request', () => {
        const newBranch = 'new-branch';

        beforeEach(async () => {
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
        it('shows a saving state', async () => {
          await mockMutate.mockImplementationOnce(() => {
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

      describe('when the commit fails', () => {
        it('shows an error message', async () => {
          mockMutate.mockRejectedValueOnce(new Error('commit failed'));

          await submitCommit();

          await waitForPromises();

          expect(findAlert().text()).toMatchInterpolatedText(
            'The GitLab CI configuration could not be updated. commit failed',
          );
        });

        it('shows an unkown error', async () => {
          mockMutate.mockRejectedValueOnce();

          await submitCommit();

          await waitForPromises();

          expect(findAlert().text()).toMatchInterpolatedText(
            'The GitLab CI configuration could not be updated.',
          );
        });
      });

      describe('when the commit form is cancelled', () => {
        const otherContent = 'other content';

        beforeEach(async () => {
          findTextEditor().vm.$emit('input', otherContent);
          await nextTick();
        });

        it('content is restored after cancel is called', async () => {
          await cancelCommitForm();

          expect(findEditorLite().attributes('value')).toBe(mockCiYml);
        });
      });
    });
  });

  describe('when queries are called', () => {
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockCiYml);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
    });

    describe('when file exists', () => {
      beforeEach(async () => {
        createComponentWithApollo();

        await waitForPromises();
      });

      it('shows editor and commit form', () => {
        expect(findEditorLite().exists()).toBe(true);
        expect(findTextEditor().exists()).toBe(true);
      });

      it('no error is shown when data is set', async () => {
        expect(findAlert().exists()).toBe(false);
        expect(findEditorLite().attributes('value')).toBe(mockCiYml);
      });

      it('ci config query is called with correct variables', async () => {
        createComponentWithApollo();

        await waitForPromises();

        expect(mockCiConfigData).toHaveBeenCalledWith({
          content: mockCiYml,
          projectPath: mockProjectFullPath,
        });
      });
    });

    describe('when no file exists', () => {
      const expectedAlertMsg =
        'There is no .gitlab-ci.yml file in this repository, please add one and visit the Pipeline Editor again.';

      it('shows a 404 error message and does not show editor or commit form', async () => {
        mockBlobContentData.mockRejectedValueOnce({
          response: {
            status: httpStatusCodes.NOT_FOUND,
          },
        });
        createComponentWithApollo();

        await waitForPromises();

        expect(findAlert().text()).toBe(expectedAlertMsg);
        expect(findEditorLite().exists()).toBe(false);
        expect(findTextEditor().exists()).toBe(false);
      });

      it('shows a 400 error message and does not show editor or commit form', async () => {
        mockBlobContentData.mockRejectedValueOnce({
          response: {
            status: httpStatusCodes.BAD_REQUEST,
          },
        });
        createComponentWithApollo();

        await waitForPromises();

        expect(findAlert().text()).toBe(expectedAlertMsg);
        expect(findEditorLite().exists()).toBe(false);
        expect(findTextEditor().exists()).toBe(false);
      });

      it('shows a unkown error message', async () => {
        mockBlobContentData.mockRejectedValueOnce(new Error('My error!'));
        createComponentWithApollo();
        await waitForPromises();

        expect(findAlert().text()).toBe('The CI configuration was not loaded, please try again.');
        expect(findEditorLite().exists()).toBe(true);
        expect(findTextEditor().exists()).toBe(true);
      });
    });
  });
});
