import { GlAlert, GlButton, GlLoadingIcon, GlTabs } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CommitForm from '~/pipeline_editor/components/commit/commit_form.vue';
import TextEditor from '~/pipeline_editor/components/editor/text_editor.vue';

import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import PipelineEditorEmptyState from '~/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';
import PipelineEditorMessages from '~/pipeline_editor/components/ui/pipeline_editor_messages.vue';
import { COMMIT_SUCCESS, COMMIT_FAILURE } from '~/pipeline_editor/constants';
import getBlobContent from '~/pipeline_editor/graphql/queries/blob_content.graphql';
import getCiConfigData from '~/pipeline_editor/graphql/queries/ci_config.graphql';
import getPipelineQuery from '~/pipeline_editor/graphql/queries/client/pipeline.graphql';
import getTemplate from '~/pipeline_editor/graphql/queries/get_starter_template.query.graphql';
import getLatestCommitShaQuery from '~/pipeline_editor/graphql/queries/latest_commit_sha.query.graphql';
import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';
import PipelineEditorHome from '~/pipeline_editor/pipeline_editor_home.vue';
import {
  mockCiConfigPath,
  mockCiConfigQueryResponse,
  mockBlobContentQueryResponse,
  mockBlobContentQueryResponseEmptyCiFile,
  mockBlobContentQueryResponseNoCiFile,
  mockDefaultBranch,
  mockProjectFullPath,
  mockCiYml,
  mockNewCommitShaResults,
} from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const MockSourceEditor = {
  template: '<div/>',
};

const mockProvide = {
  ciConfigPath: mockCiConfigPath,
  defaultBranch: mockDefaultBranch,
  glFeatures: {
    pipelineEditorEmptyStateAction: false,
  },
  projectFullPath: mockProjectFullPath,
};

describe('Pipeline editor app component', () => {
  let wrapper;

  let mockApollo;
  let mockBlobContentData;
  let mockCiConfigData;
  let mockGetTemplate;
  let mockUpdateCommitSha;
  let mockLatestCommitShaQuery;
  let mockPipelineQuery;

  const createComponent = ({ blobLoading = false, options = {}, provide = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorApp, {
      provide: { ...mockProvide, ...provide },
      stubs: {
        GlTabs,
        GlButton,
        CommitForm,
        PipelineEditorHome,
        PipelineEditorTabs,
        PipelineEditorMessages,
        SourceEditor: MockSourceEditor,
        PipelineEditorEmptyState,
      },
      mocks: {
        $apollo: {
          queries: {
            initialCiFileContent: {
              loading: blobLoading,
            },
            ciConfigData: {
              loading: false,
            },
          },
        },
      },
      ...options,
    });
  };

  const createComponentWithApollo = async ({ props = {}, provide = {} } = {}) => {
    const handlers = [
      [getBlobContent, mockBlobContentData],
      [getCiConfigData, mockCiConfigData],
      [getTemplate, mockGetTemplate],
      [getLatestCommitShaQuery, mockLatestCommitShaQuery],
      [getPipelineQuery, mockPipelineQuery],
    ];

    const resolvers = {
      Mutation: {
        updateCommitSha: mockUpdateCommitSha,
      },
    };
    mockApollo = createMockApollo(handlers, resolvers);

    const options = {
      localVue,
      data() {
        return {
          currentBranch: mockDefaultBranch,
        };
      },
      mocks: {},
      apolloProvider: mockApollo,
    };

    createComponent({ props, provide, options });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEditorHome = () => wrapper.findComponent(PipelineEditorHome);
  const findTextEditor = () => wrapper.findComponent(TextEditor);
  const findEmptyState = () => wrapper.findComponent(PipelineEditorEmptyState);
  const findEmptyStateButton = () =>
    wrapper.findComponent(PipelineEditorEmptyState).findComponent(GlButton);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
    mockCiConfigData = jest.fn();
    mockGetTemplate = jest.fn();
    mockUpdateCommitSha = jest.fn();
    mockLatestCommitShaQuery = jest.fn();
    mockPipelineQuery = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it('displays a loading icon if the blob query is loading', () => {
      createComponent({ blobLoading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTextEditor().exists()).toBe(false);
    });
  });

  describe('when queries are called', () => {
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
    });

    describe('when file exists', () => {
      beforeEach(async () => {
        await createComponentWithApollo();
      });

      it('shows pipeline editor home component', () => {
        expect(findEditorHome().exists()).toBe(true);
      });

      it('no error is shown when data is set', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('ci config query is called with correct variables', async () => {
        expect(mockCiConfigData).toHaveBeenCalledWith({
          content: mockCiYml,
          projectPath: mockProjectFullPath,
        });
      });
    });

    describe('when no CI config file exists', () => {
      it('shows an empty state and does not show editor home component', async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        await createComponentWithApollo();

        expect(findEmptyState().exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(false);
      });

      describe('because of a fetching error', () => {
        it('shows a unkown error message', async () => {
          const loadUnknownFailureText = 'The CI configuration was not loaded, please try again.';

          mockBlobContentData.mockRejectedValueOnce(new Error('My error!'));
          await createComponentWithApollo();

          expect(findEmptyState().exists()).toBe(false);

          expect(findAlert().text()).toBe(loadUnknownFailureText);
          expect(findEditorHome().exists()).toBe(true);
        });
      });
    });

    describe('with an empty CI config file', () => {
      describe('with empty state feature flag on', () => {
        it('does not show the empty screen state', async () => {
          mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseEmptyCiFile);

          await createComponentWithApollo({
            provide: {
              glFeatures: {
                pipelineEditorEmptyStateAction: true,
              },
            },
          });

          expect(findEmptyState().exists()).toBe(false);
          expect(findTextEditor().exists()).toBe(true);
        });
      });
    });

    describe('when landing on the empty state with feature flag on', () => {
      it('user can click on CTA button and see an empty editor', async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);

        await createComponentWithApollo({
          provide: {
            glFeatures: {
              pipelineEditorEmptyStateAction: true,
            },
          },
        });

        expect(findEmptyState().exists()).toBe(true);
        expect(findTextEditor().exists()).toBe(false);

        await findEmptyStateButton().vm.$emit('click');

        expect(findEmptyState().exists()).toBe(false);
        expect(findTextEditor().exists()).toBe(true);
      });
    });

    describe('when the user commits', () => {
      const updateFailureMessage = 'The GitLab CI configuration could not be updated.';
      const updateSuccessMessage = 'Your changes have been successfully committed.';

      describe('and the commit mutation succeeds', () => {
        beforeEach(() => {
          window.scrollTo = jest.fn();
          createComponent();

          findEditorHome().vm.$emit('commit', { type: COMMIT_SUCCESS });
        });

        it('shows a confirmation message', () => {
          expect(findAlert().text()).toBe(updateSuccessMessage);
        });

        it('scrolls to the top of the page to bring attention to the confirmation message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });
      });
      describe('and the commit mutation fails', () => {
        const commitFailedReasons = ['Commit failed'];

        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo();

          findEditorHome().vm.$emit('showError', {
            type: COMMIT_FAILURE,
            reasons: commitFailedReasons,
          });
        });

        it('shows an error message', () => {
          expect(findAlert().text()).toMatchInterpolatedText(
            `${updateFailureMessage} ${commitFailedReasons[0]}`,
          );
        });

        it('scrolls to the top of the page to bring attention to the error message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });
      });

      describe('when an unknown error occurs', () => {
        const unknownReasons = ['Commit failed'];

        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo();

          findEditorHome().vm.$emit('showError', {
            type: COMMIT_FAILURE,
            reasons: unknownReasons,
          });
        });

        it('shows an error message', () => {
          expect(findAlert().text()).toMatchInterpolatedText(
            `${updateFailureMessage} ${unknownReasons[0]}`,
          );
        });

        it('scrolls to the top of the page to bring attention to the error message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });
      });
    });
  });

  describe('when refetching content', () => {
    it('refetches blob content', async () => {
      await createComponentWithApollo();
      jest
        .spyOn(wrapper.vm.$apollo.queries.initialCiFileContent, 'refetch')
        .mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.initialCiFileContent.refetch).toHaveBeenCalledTimes(0);

      await wrapper.vm.refetchContent();

      expect(wrapper.vm.$apollo.queries.initialCiFileContent.refetch).toHaveBeenCalledTimes(1);
    });

    it('hides start screen when refetch fetches CI file', async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
      await createComponentWithApollo();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEditorHome().exists()).toBe(false);

      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await wrapper.vm.$apollo.queries.initialCiFileContent.refetch();

      expect(findEmptyState().exists()).toBe(false);
      expect(findEditorHome().exists()).toBe(true);
    });
  });

  describe('when a template parameter is present in the URL', () => {
    const { location } = window;

    beforeEach(() => {
      delete window.location;
      window.location = new URL('https://localhost?template=Android');
    });

    afterEach(() => {
      window.location = location;
    });

    it('renders the given template', async () => {
      await createComponentWithApollo();

      expect(mockGetTemplate).toHaveBeenCalledWith({
        projectPath: mockProjectFullPath,
        templateName: 'Android',
      });

      expect(findEmptyState().exists()).toBe(false);
      expect(findTextEditor().exists()).toBe(true);
    });
  });

  describe('when updating commit sha', () => {
    const newCommitSha = mockNewCommitShaResults.data.project.pipelines.nodes[0].sha;

    beforeEach(async () => {
      mockUpdateCommitSha.mockResolvedValue(newCommitSha);
      mockLatestCommitShaQuery.mockResolvedValue(mockNewCommitShaResults);
      await createComponentWithApollo();
    });

    it('fetches updated commit sha for the new branch', async () => {
      expect(mockLatestCommitShaQuery).not.toHaveBeenCalled();

      wrapper
        .findComponent(PipelineEditorHome)
        .vm.$emit('updateCommitSha', { newBranch: 'new-branch' });
      await waitForPromises();

      expect(mockLatestCommitShaQuery).toHaveBeenCalledWith({
        projectPath: mockProjectFullPath,
        ref: 'new-branch',
      });
    });

    it('updates commit sha with the newly fetched commit sha', async () => {
      expect(mockUpdateCommitSha).not.toHaveBeenCalled();

      wrapper
        .findComponent(PipelineEditorHome)
        .vm.$emit('updateCommitSha', { newBranch: 'new-branch' });
      await waitForPromises();

      expect(mockUpdateCommitSha).toHaveBeenCalled();
      expect(mockUpdateCommitSha).toHaveBeenCalledWith(
        expect.any(Object),
        { commitSha: mockNewCommitShaResults.data.project.pipelines.nodes[0].sha },
        expect.any(Object),
        expect.any(Object),
      );
    });
  });
});
