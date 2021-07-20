import '~/commons';
import { GlButton, GlEmptyState, GlFilteredSearch, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { chunk } from 'lodash';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { getExperimentData, getExperimentVariant } from '~/experimentation/utils';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import NavigationControls from '~/pipelines/components/pipelines_list/nav_controls.vue';
import PipelinesComponent from '~/pipelines/components/pipelines_list/pipelines.vue';
import PipelinesCiTemplates from '~/pipelines/components/pipelines_list/pipelines_ci_templates.vue';
import PipelinesTableComponent from '~/pipelines/components/pipelines_list/pipelines_table.vue';
import { RAW_TEXT_WARNING } from '~/pipelines/constants';
import Store from '~/pipelines/stores/pipelines_store';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

import { stageReply, users, mockSearch, branches } from './mock_data';

jest.mock('~/flash');
jest.mock('~/experimentation/utils', () => ({
  ...jest.requireActual('~/experimentation/utils'),
  getExperimentData: jest.fn().mockReturnValue(false),
  getExperimentVariant: jest.fn().mockReturnValue('control'),
}));

const mockProjectPath = 'twitter/flight';
const mockProjectId = '21';
const mockPipelinesEndpoint = `/${mockProjectPath}/pipelines.json`;
const mockPipelinesResponse = getJSONFixture('pipelines/pipelines.json');
const mockPipelinesIds = mockPipelinesResponse.pipelines.map(({ id }) => id);
const mockPipelineWithStages = mockPipelinesResponse.pipelines.find(
  (p) => p.details.stages && p.details.stages.length,
);

describe('Pipelines', () => {
  let wrapper;
  let mock;
  let origWindowLocation;

  const paths = {
    emptyStateSvgPath: '/assets/illustrations/pipelines_empty.svg',
    errorStateSvgPath: '/assets/illustrations/pipelines_failed.svg',
    noPipelinesSvgPath: '/assets/illustrations/pipelines_pending.svg',
    ciLintPath: '/ci/lint',
    resetCachePath: `${mockProjectPath}/settings/ci_cd/reset_cache`,
    newPipelinePath: `${mockProjectPath}/pipelines/new`,
    codeQualityPagePath: `${mockProjectPath}/-/new/master?commit_message=Add+.gitlab-ci.yml+and+create+a+code+quality+job&file_name=.gitlab-ci.yml&template=Code-Quality`,
    ciRunnerSettingsPath: `${mockProjectPath}/-/settings/ci_cd#js-runners-settings`,
  };

  const noPermissions = {
    emptyStateSvgPath: '/assets/illustrations/pipelines_empty.svg',
    errorStateSvgPath: '/assets/illustrations/pipelines_failed.svg',
    noPipelinesSvgPath: '/assets/illustrations/pipelines_pending.svg',
  };

  const defaultProps = {
    hasGitlabCi: true,
    canCreatePipeline: true,
    ...paths,
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNavigationTabs = () => wrapper.findComponent(NavigationTabs);
  const findNavigationControls = () => wrapper.findComponent(NavigationControls);
  const findPipelinesTable = () => wrapper.findComponent(PipelinesTableComponent);
  const findTablePagination = () => wrapper.findComponent(TablePagination);

  const findTab = (tab) => wrapper.findByTestId(`pipelines-tab-${tab}`);
  const findRunPipelineButton = () => wrapper.findByTestId('run-pipeline-button');
  const findCiLintButton = () => wrapper.findByTestId('ci-lint-button');
  const findCleanCacheButton = () => wrapper.findByTestId('clear-cache-button');
  const findStagesDropdownToggle = () =>
    wrapper.find('[data-testid="mini-pipeline-graph-dropdown"] .dropdown-toggle');
  const findPipelineUrlLinks = () => wrapper.findAll('[data-testid="pipeline-url-link"]');

  const createComponent = (props = defaultProps) => {
    wrapper = extendedWrapper(
      mount(PipelinesComponent, {
        provide: {
          pipelineEditorPath: '',
          suggestedCiTemplates: [],
        },
        propsData: {
          store: new Store(),
          projectId: mockProjectId,
          endpoint: mockPipelinesEndpoint,
          params: {},
          ...props,
        },
      }),
    );
  };

  beforeAll(() => {
    origWindowLocation = window.location;
    delete window.location;
    window.location = {
      search: '',
      protocol: 'https:',
    };
  });

  afterAll(() => {
    window.location = origWindowLocation;
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);

    jest.spyOn(window.history, 'pushState');
    jest.spyOn(Api, 'projectUsers').mockResolvedValue(users);
    jest.spyOn(Api, 'branches').mockResolvedValue({ data: branches });
  });

  afterEach(() => {
    wrapper.destroy();
    mock.reset();
    window.history.pushState.mockReset();
  });

  describe('when pipelines are not yet loaded', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('shows loading state when the app is loading', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
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
        .reply(200, mockPipelinesResponse);
    });

    describe('when user has no permissions', () => {
      beforeEach(async () => {
        createComponent({ hasGitlabCi: true, canCreatePipeline: false, ...noPermissions });
        await waitForPromises();
      });

      it('renders "All" tab with count different from "0"', () => {
        expect(findTab('all').text()).toMatchInterpolatedText('All 3');
      });

      it('does not render buttons', () => {
        expect(findNavigationControls().exists()).toBe(false);

        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCiLintButton().exists()).toBe(false);
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
        expect(findRunPipelineButton().attributes('href')).toBe(paths.newPipelinePath);
      });

      it('renders CI lint link', () => {
        expect(findCiLintButton().attributes('href')).toBe(paths.ciLintPath);
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
              .reply(200, {
                pipelines: [mockFinishedPipeline],
                count: mockPipelinesResponse.count,
              });

            goToTab('finished');

            await waitForPromises();
          });

          it('should filter pipelines', async () => {
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
        });

        describe('when the scope in the tab is empty', () => {
          beforeEach(async () => {
            mock
              .onGet(mockPipelinesEndpoint, { params: { scope: 'branches', page: '1' } })
              .reply(200, {
                pipelines: [],
                count: mockPipelinesResponse.count,
              });

            goToTab('branches');

            await waitForPromises();
          });

          it('should filter pipelines', async () => {
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
            .replyOnce(200, {
              pipelines: [mockFilteredPipeline],
              count: mockPipelinesResponse.count,
            });

          findFilteredSearch().vm.$emit('submit', mockSearch);

          await waitForPromises();
        });

        it('requests data with query params on filter submit', async () => {
          expect(mock.history.get[1].params).toEqual(expectedParams);
        });

        it('renders filtered pipelines', async () => {
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

      describe('when user triggers a filtered search with raw text', () => {
        beforeEach(async () => {
          findFilteredSearch().vm.$emit('submit', ['rawText']);

          await waitForPromises();
        });

        it('requests data with query params on filter submit', async () => {
          expect(mock.history.get[1].params).toEqual({ page: '1', scope: 'all' });
        });

        it('displays a warning message if raw text search is used', () => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith({ message: RAW_TEXT_WARNING, type: 'warning' });
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
      findTablePagination().find(GlPagination).vm.$emit('input', page);
    };

    beforeEach(async () => {
      mock.onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } }).reply(
        200,
        {
          pipelines: firstPage,
          count: mockPipelinesResponse.count,
        },
        mockPageHeaders({ page: 1 }),
      );
      mock.onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '2' } }).reply(
        200,
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
        .replyOnce(200, emptyResponse, {
          'POLL-INTERVAL': 100,
        });
      // Mock pipelines in the next attempt
      mock
        .onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } })
        .reply(200, mockPipelinesResponse, {
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

        it('is loading after a time', async () => {
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
      mock.onGet(mockPipelinesEndpoint, { params: { scope: 'all', page: '1' } }).reply(200, {
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
        expect(findRunPipelineButton().attributes('href')).toBe(paths.newPipelinePath);
      });

      it('renders CI lint link', () => {
        expect(findCiLintButton().attributes('href')).toBe(paths.ciLintPath);
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

      it('renders tab empty state finished scope', async () => {
        mock.onGet(mockPipelinesEndpoint, { params: { scope: 'finished', page: '1' } }).reply(200, {
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
        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...paths });
        await waitForPromises();
      });

      it('renders the CI/CD templates', () => {
        expect(wrapper.find(PipelinesCiTemplates)).toExist();
      });

      describe('when the code_quality_walkthrough experiment is active', () => {
        beforeAll(() => {
          getExperimentData.mockImplementation((name) => name === 'code_quality_walkthrough');
        });

        describe('the control state', () => {
          beforeAll(() => {
            getExperimentVariant.mockReturnValue('control');
          });

          it('renders the CI/CD templates', () => {
            expect(wrapper.find(PipelinesCiTemplates)).toExist();
          });
        });

        describe('the candidate state', () => {
          beforeAll(() => {
            getExperimentVariant.mockReturnValue('candidate');
          });

          it('renders another CTA button', () => {
            expect(findEmptyState().findComponent(GlButton).text()).toBe('Add a code quality job');
            expect(findEmptyState().findComponent(GlButton).attributes('href')).toBe(
              paths.codeQualityPagePath,
            );
          });
        });
      });

      describe('when the ci_runner_templates experiment is active', () => {
        beforeAll(() => {
          getExperimentData.mockImplementation((name) => name === 'ci_runner_templates');
        });

        describe('the control state', () => {
          beforeAll(() => {
            getExperimentVariant.mockReturnValue('control');
          });

          it('renders the CI/CD templates', () => {
            expect(wrapper.find(PipelinesCiTemplates)).toExist();
          });
        });

        describe('the candidate state', () => {
          beforeAll(() => {
            getExperimentVariant.mockReturnValue('candidate');
          });

          it('renders two buttons', () => {
            expect(findEmptyState().findAllComponents(GlButton).length).toBe(2);
            expect(findEmptyState().findAllComponents(GlButton).at(0).text()).toBe(
              'Install GitLab Runners',
            );
            expect(findEmptyState().findAllComponents(GlButton).at(0).attributes('href')).toBe(
              paths.ciRunnerSettingsPath,
            );
            expect(findEmptyState().findAllComponents(GlButton).at(1).text()).toBe(
              'Learn about Runners',
            );
            expect(findEmptyState().findAllComponents(GlButton).at(1).attributes('href')).toBe(
              '/help/ci/quick_start/index.md',
            );
          });
        });
      });

      it('does not render filtered search', () => {
        expect(findFilteredSearch().exists()).toBe(false);
      });

      it('does not render tabs nor buttons', () => {
        expect(findNavigationTabs().exists()).toBe(false);
        expect(findTab('all').exists()).toBe(false);
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCiLintButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });
    });

    describe('when CI is not enabled and user has no permissions', () => {
      beforeEach(async () => {
        createComponent({ hasGitlabCi: false, canCreatePipeline: false, ...noPermissions });
        await waitForPromises();
      });

      it('renders empty state without button to set CI', () => {
        expect(findEmptyState().text()).toBe(
          'This project is not currently set up to run pipelines.',
        );

        expect(findEmptyState().find(GlButton).exists()).toBe(false);
      });

      it('does not render tabs or buttons', () => {
        expect(findTab('all').exists()).toBe(false);
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCiLintButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });
    });

    describe('when CI is enabled and user has no permissions', () => {
      beforeEach(() => {
        createComponent({ hasGitlabCi: true, canCreatePipeline: false, ...noPermissions });

        return waitForPromises();
      });

      it('renders tab with count of "0"', () => {
        expect(findTab('all').text()).toMatchInterpolatedText('All 0');
      });

      it('does not render buttons', () => {
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCiLintButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });

      it('renders empty state', () => {
        expect(findEmptyState().text()).toBe('There are currently no pipelines.');
      });
    });
  });

  describe('when a pipeline with stages exists', () => {
    describe('updates results when a staged is clicked', () => {
      let stopMock;
      let restartMock;
      let cancelMock;

      beforeEach(() => {
        mock.onGet(mockPipelinesEndpoint, { scope: 'all', page: '1' }).reply(
          200,
          {
            pipelines: [mockPipelineWithStages],
            count: { all: '1' },
          },
          {
            'POLL-INTERVAL': 100,
          },
        );

        mock.onGet(mockPipelineWithStages.details.stages[0].dropdown_path).reply(200, stageReply);

        createComponent();

        stopMock = jest.spyOn(wrapper.vm.poll, 'stop');
        restartMock = jest.spyOn(wrapper.vm.poll, 'restart');
        cancelMock = jest.spyOn(wrapper.vm.service.cancelationSource, 'cancel');
      });

      describe('when a request is being made', () => {
        beforeEach(async () => {
          mock.onGet(mockPipelinesEndpoint).reply(200, mockPipelinesResponse);

          await waitForPromises();
        });

        it('stops polling, cancels the request, & restarts polling', async () => {
          // Mock init a polling cycle
          wrapper.vm.poll.options.notificationCallback(true);

          findStagesDropdownToggle().trigger('click');

          await waitForPromises();

          expect(cancelMock).toHaveBeenCalled();
          expect(stopMock).toHaveBeenCalled();
          expect(restartMock).toHaveBeenCalled();
        });

        it('stops polling & restarts polling', async () => {
          findStagesDropdownToggle().trigger('click');

          await waitForPromises();

          expect(cancelMock).not.toHaveBeenCalled();
          expect(stopMock).toHaveBeenCalled();
          expect(restartMock).toHaveBeenCalled();
        });
      });
    });
  });

  describe('when pipelines cannot be loaded', () => {
    beforeEach(async () => {
      mock.onGet(mockPipelinesEndpoint).reply(500, {});
    });

    describe('when user has no permissions', () => {
      beforeEach(async () => {
        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...noPermissions });

        await waitForPromises();
      });

      it('renders tabs', () => {
        expect(findNavigationTabs().exists()).toBe(true);
        expect(findTab('all').text()).toBe('All');
      });

      it('does not render buttons', () => {
        expect(findRunPipelineButton().exists()).toBe(false);
        expect(findCiLintButton().exists()).toBe(false);
        expect(findCleanCacheButton().exists()).toBe(false);
      });

      it('shows error state', () => {
        expect(findEmptyState().text()).toBe(
          'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
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
        expect(findRunPipelineButton().attributes('href')).toBe(paths.newPipelinePath);

        expect(findCiLintButton().attributes('href')).toBe(paths.ciLintPath);
        expect(findCleanCacheButton().text()).toBe('Clear runner caches');
      });

      it('shows error state', () => {
        expect(findEmptyState().text()).toBe(
          'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
        );
      });
    });
  });
});
