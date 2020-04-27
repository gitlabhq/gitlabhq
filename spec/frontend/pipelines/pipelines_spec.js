import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import PipelinesComponent from '~/pipelines/components/pipelines.vue';
import Store from '~/pipelines/stores/pipelines_store';
import { pipelineWithStages, stageReply } from './mock_data';

describe('Pipelines', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';

  preloadFixtures(jsonFixtureName);

  let pipelines;
  let wrapper;
  let mock;

  const paths = {
    endpoint: 'twitter/flight/pipelines.json',
    autoDevopsPath: '/help/topics/autodevops/index.md',
    helpPagePath: '/help/ci/quick_start/README',
    emptyStateSvgPath: '/assets/illustrations/pipelines_empty.svg',
    errorStateSvgPath: '/assets/illustrations/pipelines_failed.svg',
    noPipelinesSvgPath: '/assets/illustrations/pipelines_pending.svg',
    ciLintPath: '/ci/lint',
    resetCachePath: '/twitter/flight/settings/ci_cd/reset_cache',
    newPipelinePath: '/twitter/flight/pipelines/new',
  };

  const noPermissions = {
    endpoint: 'twitter/flight/pipelines.json',
    autoDevopsPath: '/help/topics/autodevops/index.md',
    helpPagePath: '/help/ci/quick_start/README',
    emptyStateSvgPath: '/assets/illustrations/pipelines_empty.svg',
    errorStateSvgPath: '/assets/illustrations/pipelines_failed.svg',
    noPipelinesSvgPath: '/assets/illustrations/pipelines_pending.svg',
  };

  const defaultProps = {
    hasGitlabCi: true,
    canCreatePipeline: true,
    ...paths,
  };

  const createComponent = (props = defaultProps, methods) => {
    wrapper = mount(PipelinesComponent, {
      propsData: {
        store: new Store(),
        ...props,
      },
      methods: {
        ...methods,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    pipelines = getJSONFixture(jsonFixtureName);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('With permission', () => {
    describe('With pipelines in main tab', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);
        createComponent();
        return waitForPromises();
      });

      it('renders tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');
      });

      it('renders Run Pipeline link', () => {
        expect(wrapper.find('.js-run-pipeline').attributes('href')).toBe(paths.newPipelinePath);
      });

      it('renders CI Lint link', () => {
        expect(wrapper.find('.js-ci-lint').attributes('href')).toBe(paths.ciLintPath);
      });

      it('renders Clear Runner Cache button', () => {
        expect(wrapper.find('.js-clear-cache').text()).toBe('Clear Runner Caches');
      });

      it('renders pipelines table', () => {
        expect(wrapper.findAll('.gl-responsive-table-row')).toHaveLength(
          pipelines.pipelines.length + 1,
        );
      });
    });

    describe('Without pipelines on main tab with CI', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });

        createComponent();

        return waitForPromises();
      });

      it('renders tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');
      });

      it('renders Run Pipeline link', () => {
        expect(wrapper.find('.js-run-pipeline').attributes('href')).toEqual(paths.newPipelinePath);
      });

      it('renders CI Lint link', () => {
        expect(wrapper.find('.js-ci-lint').attributes('href')).toEqual(paths.ciLintPath);
      });

      it('renders Clear Runner Cache button', () => {
        expect(wrapper.find('.js-clear-cache').text()).toEqual('Clear Runner Caches');
      });

      it('renders tab empty state', () => {
        expect(wrapper.find('.empty-state h4').text()).toEqual('There are currently no pipelines.');
      });
    });

    describe('Without pipelines nor CI', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });

        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...paths });

        return waitForPromises();
      });

      it('renders empty state', () => {
        expect(wrapper.find('.js-empty-state h4').text()).toEqual('Build with confidence');

        expect(wrapper.find('.js-get-started-pipelines').attributes('href')).toEqual(
          paths.helpPagePath,
        );
      });

      it('does not render tabs nor buttons', () => {
        expect(wrapper.find('.js-pipelines-tab-all').exists()).toBeFalsy();
        expect(wrapper.find('.js-run-pipeline').exists()).toBeFalsy();
        expect(wrapper.find('.js-ci-lint').exists()).toBeFalsy();
        expect(wrapper.find('.js-clear-cache').exists()).toBeFalsy();
      });
    });

    describe('When API returns error', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(500, {});
        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...paths });

        return waitForPromises();
      });

      it('renders tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');
      });

      it('renders buttons', () => {
        expect(wrapper.find('.js-run-pipeline').attributes('href')).toEqual(paths.newPipelinePath);

        expect(wrapper.find('.js-ci-lint').attributes('href')).toEqual(paths.ciLintPath);
        expect(wrapper.find('.js-clear-cache').text()).toEqual('Clear Runner Caches');
      });

      it('renders error state', () => {
        expect(wrapper.find('.empty-state').text()).toContain(
          'There was an error fetching the pipelines.',
        );
      });
    });
  });

  describe('Without permission', () => {
    describe('With pipelines in main tab', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        createComponent({ hasGitlabCi: false, canCreatePipeline: false, ...noPermissions });

        return waitForPromises();
      });

      it('renders tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');
      });

      it('does not render buttons', () => {
        expect(wrapper.find('.js-run-pipeline').exists()).toBeFalsy();
        expect(wrapper.find('.js-ci-lint').exists()).toBeFalsy();
        expect(wrapper.find('.js-clear-cache').exists()).toBeFalsy();
      });

      it('renders pipelines table', () => {
        expect(wrapper.findAll('.gl-responsive-table-row')).toHaveLength(
          pipelines.pipelines.length + 1,
        );
      });
    });

    describe('Without pipelines on main tab with CI', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });

        createComponent({ hasGitlabCi: true, canCreatePipeline: false, ...noPermissions });

        return waitForPromises();
      });

      it('renders tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');
      });

      it('does not render buttons', () => {
        expect(wrapper.find('.js-run-pipeline').exists()).toBeFalsy();
        expect(wrapper.find('.js-ci-lint').exists()).toBeFalsy();
        expect(wrapper.find('.js-clear-cache').exists()).toBeFalsy();
      });

      it('renders tab empty state', () => {
        expect(wrapper.find('.empty-state h4').text()).toEqual('There are currently no pipelines.');
      });
    });

    describe('Without pipelines nor CI', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, {
          pipelines: [],
          count: {
            all: 0,
            pending: 0,
            running: 0,
            finished: 0,
          },
        });

        createComponent({ hasGitlabCi: false, canCreatePipeline: false, ...noPermissions });

        return waitForPromises();
      });

      it('renders empty state without button to set CI', () => {
        expect(wrapper.find('.js-empty-state').text()).toEqual(
          'This project is not currently set up to run pipelines.',
        );

        expect(wrapper.find('.js-get-started-pipelines').exists()).toBeFalsy();
      });

      it('does not render tabs or buttons', () => {
        expect(wrapper.find('.js-pipelines-tab-all').exists()).toBeFalsy();
        expect(wrapper.find('.js-run-pipeline').exists()).toBeFalsy();
        expect(wrapper.find('.js-ci-lint').exists()).toBeFalsy();
        expect(wrapper.find('.js-clear-cache').exists()).toBeFalsy();
      });
    });

    describe('When API returns error', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(500, {});

        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...noPermissions });

        return waitForPromises();
      });

      it('renders tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');
      });

      it('does not renders buttons', () => {
        expect(wrapper.find('.js-run-pipeline').exists()).toBeFalsy();
        expect(wrapper.find('.js-ci-lint').exists()).toBeFalsy();
        expect(wrapper.find('.js-clear-cache').exists()).toBeFalsy();
      });

      it('renders error state', () => {
        expect(wrapper.find('.empty-state').text()).toContain(
          'There was an error fetching the pipelines.',
        );
      });
    });
  });

  describe('successful request', () => {
    describe('with pipelines', () => {
      beforeEach(() => {
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        createComponent();
        return waitForPromises();
      });

      it('should render table', () => {
        expect(wrapper.find('.table-holder').exists()).toBe(true);
        expect(wrapper.findAll('.gl-responsive-table-row')).toHaveLength(
          pipelines.pipelines.length + 1,
        );
      });

      it('should render navigation tabs', () => {
        expect(wrapper.find('.js-pipelines-tab-pending').text()).toContain('Pending');

        expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('All');

        expect(wrapper.find('.js-pipelines-tab-running').text()).toContain('Running');

        expect(wrapper.find('.js-pipelines-tab-finished').text()).toContain('Finished');

        expect(wrapper.find('.js-pipelines-tab-branches').text()).toContain('Branches');

        expect(wrapper.find('.js-pipelines-tab-tags').text()).toContain('Tags');
      });

      it('should make an API request when using tabs', () => {
        const updateContentMock = jest.fn(() => {});
        createComponent(
          { hasGitlabCi: true, canCreatePipeline: true, ...paths },
          {
            updateContent: updateContentMock,
          },
        );

        return waitForPromises().then(() => {
          wrapper.find('.js-pipelines-tab-finished').trigger('click');

          expect(updateContentMock).toHaveBeenCalledWith({ scope: 'finished', page: '1' });
        });
      });

      describe('with pagination', () => {
        it('should make an API request when using pagination', () => {
          const updateContentMock = jest.fn(() => {});
          createComponent(
            { hasGitlabCi: true, canCreatePipeline: true, ...paths },
            {
              updateContent: updateContentMock,
            },
          );

          return waitForPromises()
            .then(() => {
              // Mock pagination
              wrapper.vm.store.state.pageInfo = {
                page: 1,
                total: 10,
                perPage: 2,
                nextPage: 2,
                totalPages: 5,
              };

              return wrapper.vm.$nextTick();
            })
            .then(() => {
              wrapper.find('.next-page-item').trigger('click');

              expect(updateContentMock).toHaveBeenCalledWith({ scope: 'all', page: '2' });
            });
        });
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      jest.spyOn(window.history, 'pushState').mockImplementation(() => null);
    });

    describe('onChangeTab', () => {
      it('should set page to 1', () => {
        const updateContentMock = jest.fn(() => {});
        createComponent(
          { hasGitlabCi: true, canCreatePipeline: true, ...paths },
          {
            updateContent: updateContentMock,
          },
        );

        wrapper.vm.onChangeTab('running');

        expect(updateContentMock).toHaveBeenCalledWith({ scope: 'running', page: '1' });
      });
    });

    describe('onChangePage', () => {
      it('should update page and keep scope', () => {
        const updateContentMock = jest.fn(() => {});
        createComponent(
          { hasGitlabCi: true, canCreatePipeline: true, ...paths },
          {
            updateContent: updateContentMock,
          },
        );

        wrapper.vm.onChangePage(4);

        expect(updateContentMock).toHaveBeenCalledWith({ scope: wrapper.vm.scope, page: '4' });
      });
    });
  });

  describe('computed properties', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('tabs', () => {
      it('returns default tabs', () => {
        expect(wrapper.vm.tabs).toEqual([
          { name: 'All', scope: 'all', count: undefined, isActive: true },
          { name: 'Pending', scope: 'pending', count: undefined, isActive: false },
          { name: 'Running', scope: 'running', count: undefined, isActive: false },
          { name: 'Finished', scope: 'finished', count: undefined, isActive: false },
          { name: 'Branches', scope: 'branches', isActive: false },
          { name: 'Tags', scope: 'tags', isActive: false },
        ]);
      });
    });

    describe('emptyTabMessage', () => {
      it('returns message with scope', () => {
        wrapper.vm.scope = 'pending';

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.emptyTabMessage).toEqual('There are currently no pending pipelines.');
        });
      });

      it('returns message without scope when scope is `all`', () => {
        expect(wrapper.vm.emptyTabMessage).toEqual('There are currently no pipelines.');
      });
    });

    describe('stateToRender', () => {
      it('returns loading state when the app is loading', () => {
        expect(wrapper.vm.stateToRender).toEqual('loading');
      });

      it('returns error state when app has error', () => {
        wrapper.vm.hasError = true;
        wrapper.vm.isLoading = false;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.stateToRender).toEqual('error');
        });
      });

      it('returns table list when app has pipelines', () => {
        wrapper.vm.isLoading = false;
        wrapper.vm.hasError = false;
        wrapper.vm.state.pipelines = pipelines.pipelines;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.stateToRender).toEqual('tableList');
        });
      });

      it('returns empty tab when app does not have pipelines but project has pipelines', () => {
        wrapper.vm.state.count.all = 10;
        wrapper.vm.isLoading = false;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.stateToRender).toEqual('emptyTab');
        });
      });

      it('returns empty tab when project has CI', () => {
        wrapper.vm.isLoading = false;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.stateToRender).toEqual('emptyTab');
        });
      });

      it('returns empty state when project does not have pipelines nor CI', () => {
        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...paths });

        wrapper.vm.isLoading = false;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.stateToRender).toEqual('emptyState');
        });
      });
    });

    describe('shouldRenderTabs', () => {
      it('returns true when state is loading & has already made the first request', () => {
        wrapper.vm.isLoading = true;
        wrapper.vm.hasMadeRequest = true;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderTabs).toEqual(true);
        });
      });

      it('returns true when state is tableList & has already made the first request', () => {
        wrapper.vm.isLoading = false;
        wrapper.vm.state.pipelines = pipelines.pipelines;
        wrapper.vm.hasMadeRequest = true;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderTabs).toEqual(true);
        });
      });

      it('returns true when state is error & has already made the first request', () => {
        wrapper.vm.isLoading = false;
        wrapper.vm.hasError = true;
        wrapper.vm.hasMadeRequest = true;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderTabs).toEqual(true);
        });
      });

      it('returns true when state is empty tab & has already made the first request', () => {
        wrapper.vm.isLoading = false;
        wrapper.vm.state.count.all = 10;
        wrapper.vm.hasMadeRequest = true;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderTabs).toEqual(true);
        });
      });

      it('returns false when has not made first request', () => {
        wrapper.vm.hasMadeRequest = false;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderTabs).toEqual(false);
        });
      });

      it('returns false when state is empty state', () => {
        createComponent({ hasGitlabCi: false, canCreatePipeline: true, ...paths });

        wrapper.vm.isLoading = false;
        wrapper.vm.hasMadeRequest = true;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderTabs).toEqual(false);
        });
      });
    });

    describe('shouldRenderButtons', () => {
      it('returns true when it has paths & has made the first request', () => {
        wrapper.vm.hasMadeRequest = true;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderButtons).toEqual(true);
        });
      });

      it('returns false when it has not made the first request', () => {
        wrapper.vm.hasMadeRequest = false;

        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.shouldRenderButtons).toEqual(false);
        });
      });
    });
  });

  describe('updates results when a staged is clicked', () => {
    beforeEach(() => {
      const copyPipeline = Object.assign({}, pipelineWithStages);
      copyPipeline.id += 1;
      mock
        .onGet('twitter/flight/pipelines.json')
        .reply(
          200,
          {
            pipelines: [pipelineWithStages],
            count: {
              all: 1,
              finished: 1,
              pending: 0,
              running: 0,
            },
          },
          {
            'POLL-INTERVAL': 100,
          },
        )
        .onGet(pipelineWithStages.details.stages[0].dropdown_path)
        .reply(200, stageReply);

      createComponent();
    });

    describe('when a request is being made', () => {
      it('stops polling, cancels the request, & restarts polling', () => {
        const stopMock = jest.spyOn(wrapper.vm.poll, 'stop');
        const restartMock = jest.spyOn(wrapper.vm.poll, 'restart');
        const cancelMock = jest.spyOn(wrapper.vm.service.cancelationSource, 'cancel');
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        return waitForPromises()
          .then(() => {
            wrapper.vm.isMakingRequest = true;
            wrapper.find('.js-builds-dropdown-button').trigger('click');
          })
          .then(() => {
            expect(cancelMock).toHaveBeenCalled();
            expect(stopMock).toHaveBeenCalled();
            expect(restartMock).toHaveBeenCalled();
          });
      });
    });

    describe('when no request is being made', () => {
      it('stops polling & restarts polling', () => {
        const stopMock = jest.spyOn(wrapper.vm.poll, 'stop');
        const restartMock = jest.spyOn(wrapper.vm.poll, 'restart');
        mock.onGet('twitter/flight/pipelines.json').reply(200, pipelines);

        return waitForPromises()
          .then(() => {
            wrapper.find('.js-builds-dropdown-button').trigger('click');
            expect(stopMock).toHaveBeenCalled();
          })
          .then(() => {
            expect(restartMock).toHaveBeenCalled();
          });
      });
    });
  });
});
