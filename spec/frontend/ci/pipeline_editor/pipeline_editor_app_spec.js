import Vue from 'vue';
import { GlAlert, GlButton, GlLoadingIcon, GlSprintf, GlToast } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { objectToQuery, visitUrl } from '~/lib/utils/url_utility';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';
import PipelineEditorTabs from '~/ci/pipeline_editor/components/pipeline_editor_tabs.vue';
import PipelineEditorEmptyState from '~/ci/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';
import PipelineEditorMessages from '~/ci/pipeline_editor/components/ui/pipeline_editor_messages.vue';
import PipelineEditorHeader from '~/ci/pipeline_editor/components/header/pipeline_editor_header.vue';
import ValidationSegment, {
  i18n as validationSegmenti18n,
} from '~/ci/pipeline_editor/components/header/validation_segment.vue';
import {
  COMMIT_SUCCESS,
  COMMIT_SUCCESS_WITH_REDIRECT,
  COMMIT_FAILURE,
  EDITOR_APP_STATUS_LOADING,
} from '~/ci/pipeline_editor/constants';
import getBlobContent from '~/ci/pipeline_editor/graphql/queries/blob_content.query.graphql';
import getCiConfigData from '~/ci/pipeline_editor/graphql/queries/ci_config.query.graphql';
import getTemplate from '~/ci/pipeline_editor/graphql/queries/get_starter_template.query.graphql';
import getLatestCommitShaQuery from '~/ci/pipeline_editor/graphql/queries/latest_commit_sha.query.graphql';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import getAppStatus from '~/ci/pipeline_editor/graphql/queries/client/app_status.query.graphql';

import PipelineEditorApp from '~/ci/pipeline_editor/pipeline_editor_app.vue';
import PipelineEditorHome from '~/ci/pipeline_editor/pipeline_editor_home.vue';

import {
  mockCiConfigPath,
  mockCiConfigQueryResponse,
  mockBlobContentQueryResponse,
  mockBlobContentQueryResponseNoCiFile,
  mockCiYml,
  mockCiTemplateQueryResponse,
  mockCommitSha,
  mockCommitShaResults,
  mockDefaultBranch,
  mockEmptyCommitShaResults,
  mockNewCommitShaResults,
  mockNewMergeRequestPath,
  mockProjectFullPath,
} from './mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const defaultProvide = {
  ciConfigPath: mockCiConfigPath,
  defaultBranch: mockDefaultBranch,
  newMergeRequestPath: mockNewMergeRequestPath,
  projectFullPath: mockProjectFullPath,
  usesExternalConfig: false,
};

Vue.use(GlToast);

describe('Pipeline editor app component', () => {
  let wrapper;

  let mockApollo;
  let mockBlobContentData;
  let mockCiConfigData;
  let mockGetTemplate;
  let mockLatestCommitShaQuery;
  const showToastMock = jest.fn();

  const createComponent = ({ options = {}, provide = {}, stubs = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorApp, {
      provide: { ...defaultProvide, ...provide },
      stubs,
      ...options,
    });
  };

  const createComponentWithApollo = ({
    provide = {},
    stubs = {},
    withUndefinedBranch = false,
  } = {}) => {
    Vue.use(VueApollo);

    const handlers = [
      [getBlobContent, mockBlobContentData],
      [getCiConfigData, mockCiConfigData],
      [getTemplate, mockGetTemplate],
      [getLatestCommitShaQuery, mockLatestCommitShaQuery],
    ];

    mockApollo = createMockApollo(handlers, resolvers);

    if (!withUndefinedBranch) {
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
    }

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getAppStatus,
      data: {
        app: {
          __typename: 'AppData',
          status: EDITOR_APP_STATUS_LOADING,
        },
      },
    });

    const options = {
      mocks: {
        $toast: {
          show: showToastMock,
        },
      },
      apolloProvider: mockApollo,
    };

    createComponent({ provide, stubs, options });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEditorHome = () => wrapper.findComponent(PipelineEditorHome);
  const findEmptyState = () => wrapper.findComponent(PipelineEditorEmptyState);
  const findEmptyStateButton = () => findEmptyState().findComponent(GlButton);
  const findValidationSegment = () => wrapper.findComponent(ValidationSegment);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
    mockCiConfigData = jest.fn();
    mockGetTemplate = jest.fn();
    mockLatestCommitShaQuery = jest.fn();
  });

  describe('loading state', () => {
    it('displays a loading icon if the blob query is loading', () => {
      createComponentWithApollo();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEditorHome().exists()).toBe(false);
    });
  });

  describe('skipping queries', () => {
    describe('when branchName is undefined', () => {
      beforeEach(async () => {
        await createComponentWithApollo({ withUndefinedBranch: true });
      });

      it('does not calls getBlobContent', () => {
        expect(mockBlobContentData).not.toHaveBeenCalled();
      });
    });

    describe('when branchName is defined', () => {
      beforeEach(async () => {
        await createComponentWithApollo();
      });

      it('calls getBlobContent', () => {
        expect(mockBlobContentData).toHaveBeenCalled();
      });
    });

    describe('when commit sha is undefined', () => {
      beforeEach(async () => {
        mockLatestCommitShaQuery.mockResolvedValue(undefined);
        await createComponentWithApollo();
      });

      it('calls getBlobContent', () => {
        expect(mockBlobContentData).toHaveBeenCalled();
      });

      it('does not call ciConfigData', () => {
        expect(mockCiConfigData).not.toHaveBeenCalled();
      });
    });

    describe('when commit sha is defined', () => {
      beforeEach(async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
        mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
        await createComponentWithApollo();
      });

      it('calls ciConfigData', () => {
        expect(mockCiConfigData).toHaveBeenCalled();
      });
    });
  });

  describe('when queries are called', () => {
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
      mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
    });

    describe('when project uses an external CI config file', () => {
      beforeEach(async () => {
        await createComponentWithApollo({
          provide: {
            usesExternalConfig: true,
          },
        });
      });

      it('shows an empty state and does not show editor home component', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(false);
      });
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

      it('ci config query is called with correct variables', () => {
        expect(mockCiConfigData).toHaveBeenCalledWith({
          content: mockCiYml,
          projectPath: mockProjectFullPath,
          sha: mockCommitSha,
        });
      });

      it('calls once and does not  start poll for the commit sha', () => {
        expect(mockLatestCommitShaQuery).toHaveBeenCalledTimes(1);
      });
    });

    describe('when no CI config file exists', () => {
      beforeEach(async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        await createComponentWithApollo({
          stubs: {
            PipelineEditorEmptyState,
          },
        });
      });

      it('shows an empty state and does not show editor home component', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(false);
      });

      it('calls once and does not  start poll for the commit sha', () => {
        expect(mockLatestCommitShaQuery).toHaveBeenCalledTimes(1);
      });

      describe('because of a fetching error', () => {
        it('shows a unkown error message', async () => {
          const loadUnknownFailureText = 'The CI configuration was not loaded, please try again.';

          mockBlobContentData.mockRejectedValueOnce();
          await createComponentWithApollo({
            stubs: {
              PipelineEditorMessages,
            },
          });

          expect(findEmptyState().exists()).toBe(false);

          expect(findAlert().text()).toBe(loadUnknownFailureText);
          expect(findEditorHome().exists()).toBe(true);
        });
      });
    });

    describe('with no CI config setup', () => {
      it('user can click on CTA button to get started', async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        mockLatestCommitShaQuery.mockResolvedValue(mockEmptyCommitShaResults);

        await createComponentWithApollo({
          stubs: {
            PipelineEditorHome,
            PipelineEditorEmptyState,
          },
        });

        expect(findEmptyState().exists()).toBe(true);
        expect(findEditorHome().exists()).toBe(false);

        await findEmptyStateButton().vm.$emit('click');

        expect(findEmptyState().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(true);
      });
    });

    describe('when the lint query returns a 500 error', () => {
      beforeEach(async () => {
        mockCiConfigData.mockRejectedValueOnce(new Error(HTTP_STATUS_INTERNAL_SERVER_ERROR));
        await createComponentWithApollo({
          stubs: { PipelineEditorHome, PipelineEditorHeader, ValidationSegment },
        });
      });

      it('shows that the lint service is down', () => {
        const validationMessage = findValidationSegment().findComponent(GlSprintf);

        expect(validationMessage.attributes('message')).toContain(
          validationSegmenti18n.unavailableValidation,
        );
      });

      it('does not report an error or scroll to the top', () => {
        expect(findAlert().exists()).toBe(false);
        expect(window.scrollTo).not.toHaveBeenCalled();
      });
    });

    describe('when the user commits', () => {
      const updateFailureMessage = 'The GitLab CI configuration could not be updated.';
      const updateSuccessMessage = 'Your changes have been successfully committed.';

      describe('and the commit mutation succeeds', () => {
        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('commit', { type: COMMIT_SUCCESS });
        });

        it('shows a toast message for successful commit type', () => {
          expect(showToastMock).toHaveBeenCalledWith(updateSuccessMessage);
        });

        it('scrolls to the top of the page to bring attention to the confirmation message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });

        it('polls for commit sha while pipeline data is not yet available for current branch', async () => {
          findEditorHome().vm.$emit('updateCommitSha');
          await waitForPromises();

          expect(mockLatestCommitShaQuery).toHaveBeenCalledTimes(2);
        });

        it('stops polling for commit sha when pipeline data is available for newly committed branch', async () => {
          mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
          await waitForPromises();

          await findEditorHome().vm.$emit('updateCommitSha');

          expect(mockLatestCommitShaQuery).toHaveBeenCalledTimes(2);
        });

        it('stops polling for commit sha when pipeline data is available for current branch', async () => {
          mockLatestCommitShaQuery.mockResolvedValue(mockNewCommitShaResults);
          findEditorHome().vm.$emit('updateCommitSha');
          await waitForPromises();

          expect(mockLatestCommitShaQuery).toHaveBeenCalledTimes(2);
        });
      });

      describe('and the commit mutation succeeds with unknown success commit type', () => {
        const defaultSuccessMessage = 'Your action succeeded.';

        beforeEach(async () => {
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('commit', { type: 'unknown' });
        });

        it('shows a toast message for unknown successful commit type', () => {
          expect(showToastMock).toHaveBeenCalledWith(defaultSuccessMessage);
        });
      });

      describe('when the commit succeeds with a redirect', () => {
        const newBranch = 'new-branch';
        const updateSuccessWithRedirectMessage =
          'Your changes have been successfully committed. Now redirecting to the new merge request page.';

        beforeEach(async () => {
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('commit', {
            type: COMMIT_SUCCESS_WITH_REDIRECT,
            params: { sourceBranch: newBranch, targetBranch: mockDefaultBranch },
          });
        });

        it('shows a toast message for successful commit with redirect type', () => {
          expect(showToastMock).toHaveBeenCalledWith(updateSuccessWithRedirectMessage);
        });

        it('redirects to the merge request page with source and target branches', () => {
          const branchesQuery = objectToQuery({
            'merge_request[source_branch]': newBranch,
            'merge_request[target_branch]': mockDefaultBranch,
          });

          expect(visitUrl).toHaveBeenCalledWith(`${mockNewMergeRequestPath}?${branchesQuery}`);
        });
      });

      describe('and the commit mutation fails', () => {
        const commitFailedReasons = ['Commit failed'];

        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

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
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

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
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
      mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
    });

    it('refetches blob content', async () => {
      await createComponentWithApollo();

      expect(mockBlobContentData).toHaveBeenCalledTimes(1);

      findEditorHome().vm.$emit('refetchContent');

      expect(mockBlobContentData).toHaveBeenCalledTimes(2);
    });

    it('hides start screen when refetch fetches CI file', async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
      await createComponentWithApollo();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEditorHome().exists()).toBe(false);

      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      findEmptyState().vm.$emit('refetchContent');
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
      expect(findEditorHome().exists()).toBe(true);
    });
  });

  describe('when a template parameter is present in the URL', () => {
    const originalLocation = window.location.href;

    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
      mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
      mockGetTemplate.mockResolvedValue(mockCiTemplateQueryResponse);
      setWindowLocation('?template=Android');
    });

    afterEach(() => {
      setWindowLocation(originalLocation);
    });

    it('renders the given template', async () => {
      await createComponentWithApollo({
        stubs: { PipelineEditorHome, PipelineEditorTabs },
      });

      expect(mockGetTemplate).toHaveBeenCalledWith({
        projectPath: mockProjectFullPath,
        templateName: 'Android',
      });

      expect(findEmptyState().exists()).toBe(false);
      expect(findEditorHome().exists()).toBe(true);
    });
  });

  describe('when add_new_config_file query param is present', () => {
    const originalLocation = window.location.href;

    beforeEach(() => {
      setWindowLocation('?add_new_config_file=true');

      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
    });

    afterEach(() => {
      setWindowLocation(originalLocation);
    });

    describe('when CI config file does not exist', () => {
      beforeEach(async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        mockLatestCommitShaQuery.mockResolvedValue(mockEmptyCommitShaResults);
        mockGetTemplate.mockResolvedValue(mockCiTemplateQueryResponse);

        await createComponentWithApollo();
      });

      it('skips empty state and shows editor home component', () => {
        expect(findEmptyState().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(true);
      });
    });
  });
});
