import '~/commons';
import {
  GlButton,
  GlCollapsibleListbox,
  GlEmptyState,
  GlFilteredSearch,
  GlLoadingIcon,
  GlPagination,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { chunk } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import mockPipelinesResponse from 'test_fixtures/pipelines/pipelines.json';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Api from '~/api';
import { createAlert, VARIANT_WARNING } from '~/alert';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import NavigationControls from '~/ci/pipelines_page/components/nav_controls.vue';
import PipelinesComponent from '~/ci/pipelines_page/pipelines.vue';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';
import PipelinesTableComponent from '~/ci/common/pipelines_table.vue';
import {
  PIPELINE_ID_KEY,
  PIPELINE_IID_KEY,
  RAW_TEXT_WARNING,
  TRACKING_CATEGORIES,
} from '~/ci/constants';
import Store from '~/ci/pipeline_details/stores/pipelines_store';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import {
  setIdTypePreferenceMutationResponse,
  setIdTypePreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import { branches, mockSearch, users } from '../pipeline_details/mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/alert');

const mockProjectPath = 'twitter/flight';
const mockProjectId = '21';
const mockDefaultBranchName = 'main';
const mockPipelinesEndpoint = `/${mockProjectPath}/pipelines.json`;
const mockPipelinesIds = mockPipelinesResponse.pipelines.map(({ id }) => id);

const skipReason = new SkipReason({
  name: 'Pipelines',
  reason: 'OOM on the worker',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/458411',
});

describeSkipVue3(skipReason, () => {
  let wrapper;
  let mockApollo;
  let mock;
  let trackingSpy;
  let mutationMock;

  const withPermissionsProps = {
    resetCachePath: `${mockProjectPath}/settings/ci_cd/reset_cache`,
    newPipelinePath: `${mockProjectPath}/pipelines/new`,
    ciRunnerSettingsPath: `${mockProjectPath}/-/settings/ci_cd#js-runners-settings`,
  };

  const defaultProps = {
    hasGitlabCi: true,
    endpoint: mockPipelinesEndpoint,
    params: {},
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNavigationTabs = () => wrapper.findComponent(NavigationTabs);
  const findNavigationControls = () => wrapper.findComponent(NavigationControls);
  const findPipelinesTable = () => wrapper.findComponent(PipelinesTableComponent);
  const findTablePagination = () => wrapper.findComponent(TablePagination);
  const findPipelineKeyCollapsibleBox = () => wrapper.findComponent(GlCollapsibleListbox);

  const findTab = (tab) => wrapper.findByTestId(`pipelines-tab-${tab}`);
  const findRunPipelineButton = () => wrapper.findByTestId('run-pipeline-button');
  const findCleanCacheButton = () => wrapper.findByTestId('clear-cache-button');
  const findPipelineUrlLinks = () => wrapper.findAll('[data-testid="pipeline-url-link"]');

  const createComponent = ({ props = {}, withPermissions = true } = {}) => {
    mockApollo = createMockApollo([[setSortPreferenceMutation, mutationMock]]);
    const permissionsProps = withPermissions ? { ...withPermissionsProps } : {};

    wrapper = extendedWrapper(
      mount(PipelinesComponent, {
        provide: {
          canCreatePipeline: withPermissions,
          defaultBranchName: mockDefaultBranchName,
          pipelineEditorPath: '',
          pipelinesAnalyticsPath: 'pipeline/analytics',
          projectId: mockProjectId,
          suggestedCiTemplates: [],
          ciRunnerSettingsPath: defaultProps.ciRunnerSettingsPath,
          anyRunnersAvailable: true,
          showJenkinsCiPrompt: false,
          identityVerificationRequired: false,
          identityVerificationPath: '#',
        },
        propsData: {
          ...defaultProps,
          ...permissionsProps,
          ...props,
          store: new Store(),
        },
        apolloProvider: mockApollo,
      }),
    );
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    setWindowLocation(TEST_HOST);
    mutationMock = jest.fn();

    jest.spyOn(window.history, 'pushState');
    jest.spyOn(Api, 'projectUsers').mockResolvedValue(users);
    jest.spyOn(Api, 'branches').mockResolvedValue({ data: branches });
  });

  afterEach(() => {
    mock.reset();
    mockApollo = null;
    window.history.pushState.mockReset();
  });

  describe('when pipelines are not yet loaded', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('shows loading state when the app is loading', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not display tabs when the first request has not yet been made', () => {
      expect(findNavigationTabs().exists()).toBe(false);
    });

    it('does not display buttons', () => {
      expect(findNavigationControls().exists()).toBe(false);
    });
  });

  describe('when there are pipelines in the project', () => {
    beforeEach(() => {
      mock
        .onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } })
        .reply(HTTP_STATUS_OK, mockPipelinesResponse);
    });

    describe('when user has no permissions', () => {
      beforeEach(async () => {
        createComponent({
          withPermissions: false,
        });
        await waitForPromises();
      });

      it('renders "All" tab with count different from "0"', () => {
        expect(findTab('all').text()).toMatchInterpolatedText('All 3');
      });

      it('does not render buttons', () => {
        expect(findNavigationControls().exists()).toBe(false);

        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });

      it('renders pipelines in a table', () => {
        expect(findPipelinesTable().exists()).toBe(true);

        expect(findPipelineUrlLinks()).toHaveLength(mockPipelinesIds.length);
        expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockPipelinesIds[0]}`);
        expect(findPipelineUrlLinks().at(1).text()).toBe(`#${mockPipelinesIds[1]}`);
        expect(findPipelineUrlLinks().at(2).text()).toBe(`#${mockPipelinesIds[2]}`);
      });
    });

    describe('when user has permissions', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('should set up navigation tabs', () => {
        expect(findNavigationTabs().props('tabs')).toEqual([
          { name: 'All', scope: 'all', count: '3', isActive: true },
          { name: 'Finished', scope: 'finished', count: undefined, isActive: false },
          { name: 'Branches', scope: 'branches', isActive: false },
          { name: 'Tags', scope: 'tags', isActive: false },
        ]);
      });

      it('renders "All" tab with count different from "0"', () => {
        expect(findTab('all').text()).toMatchInterpolatedText('All 3');
      });

      it('should render other navigation tabs', () => {
        expect(findTab('finished').text()).toBe('Finished');
        expect(findTab('branches').text()).toBe('Branches');
        expect(findTab('tags').text()).toBe('Tags');
      });

      it('shows navigation controls', () => {
        expect(findNavigationControls().exists()).toBe(true);
      });

      it('renders Run pipeline link', () => {
        expect(findRunPipelineButton().attributes('href')).toBe(
          withPermissionsProps.newPipelinePath,
        );
      });

      it('renders Clear runner cache button', () => {
        expect(findCleanCacheButton().text()).toBe('Clear runner caches');
      });

      it('renders pipelines in a table', () => {
        expect(findPipelinesTable().exists()).toBe(true);

        expect(findPipelineUrlLinks()).toHaveLength(mockPipelinesIds.length);
        expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockPipelinesIds[0]}`);
        expect(findPipelineUrlLinks().at(1).text()).toBe(`#${mockPipelinesIds[1]}`);
        expect(findPipelineUrlLinks().at(2).text()).toBe(`#${mockPipelinesIds[2]}`);
      });

      describe('when user goes to a tab', () => {
        const goToTab = (tab) => {
          findNavigationTabs().vm.$emit('onChangeTab', tab);
        };

        describe('when the scope in the tab has pipelines', () => {
          const mockFinishedPipeline = mockPipelinesResponse.pipelines[0];

          beforeEach(async () => {
            mock
              .onGet(mockPipelinesEndpoint, { params: { scope: 'finished', page: '1' } })
              .reply(HTTP_STATUS_OK, {
                pipelines: [mockFinishedPipeline],
                count: mockPipelinesResponse.count,
              });

            trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

            goToTab('finished');

            await waitForPromises();
          });

          it('should filter pipelines', () => {
            expect(findPipelinesTable().exists()).toBe(true);

            expect(findPipelineUrlLinks()).toHaveLength(1);
            expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockFinishedPipeline.id}`);
          });

          it('should update browser bar', () => {
            expect(window.history.pushState).toHaveBeenCalledTimes(1);
            expect(window.history.pushState).toHaveBeenCalledWith(
              expect.anything(),
              expect.anything(),
              `${window.location.pathname}?scope=finished&page=1`,
            );
          });

          it.each(['all', 'finished', 'branches', 'tags'])('tracks %p tab click', async (scope) => {
            goToTab(scope);

            await waitForPromises();

            expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_filter_tabs', {
              label: TRACKING_CATEGORIES.tabs,
              property: scope,
            });
          });
        });

        describe('when the scope in the tab is empty', () => {
          beforeEach(async () => {
            mock
              .onGet(mockPipelinesEndpoint, { params: { scope: 'branches', page: '1' } })
              .reply(HTTP_STATUS_OK, {
                pipelines: [],
                count: mockPipelinesResponse.count,
              });

            goToTab('branches');

            await waitForPromises();
          });

          it('should filter pipelines', () => {
            expect(findEmptyState().text()).toBe('There are currently no pipelines.');
          });

          it('should update browser bar', () => {
            expect(window.history.pushState).toHaveBeenCalledTimes(1);
            expect(window.history.pushState).toHaveBeenCalledWith(
              expect.anything(),
              expect.anything(),
              `${window.location.pathname}?scope=branches&page=1`,
            );
          });
        });
      });

      describe('when user triggers a filtered search', () => {
        const mockFilteredPipeline = mockPipelinesResponse.pipelines[1];

        let expectedParams;

        beforeEach(async () => {
          expectedParams = {
            page: '1',
            scope: 'all',
            username: 'root',
            ref: 'main',
            status: 'pending',
          };

          mock
            .onGet(mockPipelinesEndpoint, {
              params: expectedParams,
            })
            .replyOnce(HTTP_STATUS_OK, {
              pipelines: [mockFilteredPipeline],
              count: mockPipelinesResponse.count,
            });

          findFilteredSearch().vm.$emit('submit', mockSearch);

          await waitForPromises();
        });

        it('requests data with query params on filter submit', () => {
          expect(mock.history.get[1].params).toEqual(expectedParams);
        });

        it('renders filtered pipelines', () => {
          expect(findPipelineUrlLinks()).toHaveLength(1);
          expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockFilteredPipeline.id}`);
        });

        it('should update browser bar', () => {
          expect(window.history.pushState).toHaveBeenCalledTimes(1);
          expect(window.history.pushState).toHaveBeenCalledWith(
            expect.anything(),
            expect.anything(),
            `${window.location.pathname}?page=1&scope=all&username=root&ref=main&status=pending`,
          );
        });
      });

      describe('when user changes Show Pipeline ID to Show Pipeline IID', () => {
        const mockFilteredPipeline = mockPipelinesResponse.pipelines[0];

        beforeEach(() => {
          gon.current_user_id = 1;

          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        });

        it('should change the text to Show Pipeline IID', async () => {
          expect(findPipelineKeyCollapsibleBox().exists()).toBe(true);
          expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockFilteredPipeline.id}`);
          findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

          await waitForPromises();

          expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockFilteredPipeline.iid}`);
        });

        it('tracks the iid usage of the ID/IID dropdown', async () => {
          findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

          await waitForPromises();

          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'pipelines_display_options', {
            label: TRACKING_CATEGORIES.listbox,
            property: 'iid',
          });
        });

        it('does not track the id usage of the ID/IID dropdown', async () => {
          findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_ID_KEY);

          await waitForPromises();

          expect(trackingSpy).not.toHaveBeenCalled();
        });

        it('calls mutation to save idType preference', () => {
          mutationMock = jest.fn().mockResolvedValue(setIdTypePreferenceMutationResponse);
          createComponent();

          findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

          expect(mutationMock).toHaveBeenCalledWith({
            input: { visibilityPipelineIdType: PIPELINE_IID_KEY.toUpperCase() },
          });
        });

        it('captures error when mutation response has errors', async () => {
          mutationMock = jest.fn().mockResolvedValue(setIdTypePreferenceMutationResponseWithErrors);
          createComponent();

          findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user triggers a filtered search with raw text', () => {
        beforeEach(async () => {
          findFilteredSearch().vm.$emit('submit', ['rawText']);

          await waitForPromises();
        });

        it('requests data with query params on filter submit', () => {
          expect(mock.history.get[1].params).toEqual({ page: '1', scope: 'all' });
        });

        it('displays a warning message if raw text search is used', () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: RAW_TEXT_WARNING,
            variant: VARIANT_WARNING,
          });
        });

        it('should update browser bar', () => {
          expect(window.history.pushState).toHaveBeenCalledTimes(1);
          expect(window.history.pushState).toHaveBeenCalledWith(
            expect.anything(),
            expect.anything(),
            `${window.location.pathname}?page=1&scope=all`,
          );
        });
      });
    });
  });

  describe('when there are multiple pages of pipelines', () => {
    const mockPageSize = 2;
    const mockPageHeaders = ({ page = 1 } = {}) => {
      return {
        'X-PER-PAGE': `${mockPageSize}`,
        'X-PREV-PAGE': `${page - 1}`,
        'X-PAGE': `${page}`,
        'X-NEXT-PAGE': `${page + 1}`,
      };
    };
    const [firstPage, secondPage] = chunk(mockPipelinesResponse.pipelines, mockPageSize);

    const goToPage = (page) => {
      findTablePagination().findComponent(GlPagination).vm.$emit('input', page);
    };

    beforeEach(async () => {
      mock.onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } }).reply(
        HTTP_STATUS_OK,
        {
          pipelines: firstPage,
          count: mockPipelinesResponse.count,
        },
        mockPageHeaders({ page: 1 }),
      );
      mock.onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '2' } }).reply(
        HTTP_STATUS_OK,
        {
          pipelines: secondPage,
          count: mockPipelinesResponse.count,
        },
        mockPageHeaders({ page: 2 }),
      );

      createComponent();

      await waitForPromises();
    });

    it('shows the first page of pipelines', () => {
      expect(findPipelineUrlLinks()).toHaveLength(firstPage.length);
      expect(findPipelineUrlLinks().at(0).text()).toBe(`#${firstPage[0].id}`);
      expect(findPipelineUrlLinks().at(1).text()).toBe(`#${firstPage[1].id}`);
    });

    it('should not update browser bar', () => {
      expect(window.history.pushState).not.toHaveBeenCalled();
    });

    describe('when user goes to next page', () => {
      beforeEach(async () => {
        goToPage(2);
        await waitForPromises();
      });

      it('should update page and keep scope the same scope', () => {
        expect(findPipelineUrlLinks()).toHaveLength(secondPage.length);
        expect(findPipelineUrlLinks().at(0).text()).toBe(`#${secondPage[0].id}`);
      });

      it('should update browser bar', () => {
        expect(window.history.pushState).toHaveBeenCalledTimes(1);
        expect(window.history.pushState).toHaveBeenCalledWith(
          expect.anything(),
          expect.anything(),
          `${window.location.pathname}?page=2&scope=all`,
        );
      });

      it('should reset page to 1 when filtering pipelines', () => {
        expect(window.history.pushState).toHaveBeenCalledTimes(1);
        expect(window.history.pushState).toHaveBeenCalledWith(
          expect.anything(),
          expect.anything(),
          `${window.location.pathname}?page=2&scope=all`,
        );

        findFilteredSearch().vm.$emit('submit', [
          { type: 'status', value: { data: 'success', operator: '=' } },
        ]);

        expect(window.history.pushState).toHaveBeenCalledTimes(2);
        expect(window.history.pushState).toHaveBeenCalledWith(
          expect.anything(),
          expect.anything(),
          `${window.location.pathname}?page=1&scope=all&status=success`,
        );
      });
    });
  });

  describe('when pipelines can be polled', () => {
    beforeEach(() => {
      const emptyResponse = {
        pipelines: [],
        count: { all: '0' },
      };

      // Mock no pipelines in the first attempt
      mock
        .onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } })
        .replyOnce(HTTP_STATUS_OK, emptyResponse, {
          'POLL-INTERVAL': 100,
        });
      // Mock pipelines in the next attempt
      mock
        .onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } })
        .reply(HTTP_STATUS_OK, mockPipelinesResponse, {
          'POLL-INTERVAL': 100,
        });
    });

    describe('data is loaded for the first time', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('shows tabs', () => {
        expect(findNavigationTabs().exists()).toBe(true);
      });

      it('should update page and keep scope the same scope', () => {
        expect(findPipelineUrlLinks()).toHaveLength(0);
      });

      describe('data is loaded for a second time', () => {
        beforeEach(async () => {
          jest.runOnlyPendingTimers();
          await waitForPromises();
        });

        it('shows tabs', () => {
          expect(findNavigationTabs().exists()).toBe(true);
        });

        it('is loading after a time', () => {
          expect(findPipelineUrlLinks()).toHaveLength(mockPipelinesIds.length);
          expect(findPipelineUrlLinks().at(0).text()).toBe(`#${mockPipelinesIds[0]}`);
          expect(findPipelineUrlLinks().at(1).text()).toBe(`#${mockPipelinesIds[1]}`);
          expect(findPipelineUrlLinks().at(2).text()).toBe(`#${mockPipelinesIds[2]}`);
        });
      });
    });
  });

  describe('when no pipelines exist', () => {
    beforeEach(() => {
      mock
        .onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } })
        .reply(HTTP_STATUS_OK, {
          pipelines: [],
          count: { all: '0' },
        });
    });

    describe('when CI is enabled and user has permissions', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders tab with count of "0"', () => {
        expect(findNavigationTabs().exists()).toBe(true);
        expect(findTab('all').text()).toMatchInterpolatedText('All 0');
      });

      it('renders Run pipeline link', () => {
        expect(findRunPipelineButton().attributes('href')).toBe(
          withPermissionsProps.newPipelinePath,
        );
      });

      it('renders Clear runner cache button', () => {
        expect(findCleanCacheButton().text()).toBe('Clear runner caches');
      });

      it('renders empty state', () => {
        expect(findEmptyState().text()).toBe('There are currently no pipelines.');
      });

      it('renders filtered search', () => {
        expect(findFilteredSearch().exists()).toBe(true);
      });

      it('renders the pipeline key collapsible box', () => {
        expect(findPipelineKeyCollapsibleBox().exists()).toBe(true);
      });

      it('renders tab empty state finished scope', async () => {
        mock
          .onGet(mockPipelinesEndpoint, { params: { scope: 'finished', page: '1' } })
          .reply(HTTP_STATUS_OK, {
            pipelines: [],
            count: { all: '0' },
          });

        findNavigationTabs().vm.$emit('onChangeTab', 'finished');

        await waitForPromises();

        expect(findEmptyState().text()).toBe('There are currently no finished pipelines.');
      });
    });

    describe('when CI is not enabled and user has permissions', () => {
      beforeEach(async () => {
        createComponent({ props: { hasGitlabCi: false } });
        await waitForPromises();
      });

      it('renders the CI/CD templates', () => {
        expect(wrapper.findComponent(PipelinesCiTemplates).exists()).toBe(true);
      });

      it('does not render filtered search', () => {
        expect(findFilteredSearch().exists()).toBe(false);
      });

      it('does not render the pipeline key dropdown', () => {
        expect(findPipelineKeyCollapsibleBox().exists()).toBe(false);
      });

      it('does not render tabs nor buttons', () => {
        expect(findNavigationTabs().exists()).toBe(false);
        expect(findTab('all').exists()).toBe(false);
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });
    });

    describe('when CI is not enabled and user has no permissions', () => {
      beforeEach(async () => {
        createComponent({ props: { hasGitlabCi: false }, withPermissions: false });
        await waitForPromises();
      });

      it('renders empty state without button to set CI', () => {
        expect(findEmptyState().text()).toBe(
          'This project is not currently set up to run pipelines.',
        );

        expect(findEmptyState().findComponent(GlButton).exists()).toBe(false);
      });

      it('does not render tabs or buttons', () => {
        expect(findTab('all').exists()).toBe(false);
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });
    });

    describe('when CI is enabled and user has no permissions', () => {
      beforeEach(() => {
        createComponent({ props: { hasGitlabCi: true }, withPermissions: false });

        return waitForPromises();
      });

      it('renders tab with count of "0"', () => {
        expect(findTab('all').text()).toMatchInterpolatedText('All 0');
      });

      it('does not render buttons', () => {
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });

      it('renders empty state', () => {
        expect(findEmptyState().text()).toBe('There are currently no pipelines.');
      });
    });
  });

  describe('when pipelines cannot be loaded', () => {
    beforeEach(() => {
      mock.onGet(mockPipelinesEndpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
    });

    describe('when user has no permissions', () => {
      beforeEach(async () => {
        createComponent({
          props: { hasGitlabCi: false },
          withPermissions: false,
        });
        await waitForPromises();
      });

      it('renders tabs', () => {
        expect(findNavigationTabs().exists()).toBe(true);
        expect(findTab('all').text()).toBe('All');
      });

      it('does not render buttons', () => {
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });

      it('shows error state', () => {
        expect(findEmptyState().props('title')).toBe('There was an error fetching the pipelines.');
        expect(findEmptyState().props('description')).toBe(
          'Try again in a few moments or contact your support team.',
        );
      });
    });

    describe('when user has permissions', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('renders tabs', () => {
        expect(findTab('all').text()).toBe('All');
      });

      it('renders buttons', () => {
        expect(findRunPipelineButton().attributes('href')).toBe(
          withPermissionsProps.newPipelinePath,
        );
        expect(findCleanCacheButton().text()).toBe('Clear runner caches');
      });

      it('shows error state', () => {
        expect(findEmptyState().props('title')).toBe('There was an error fetching the pipelines.');
        expect(findEmptyState().props('description')).toBe(
          'Try again in a few moments or contact your support team.',
        );
      });
    });
  });
});
