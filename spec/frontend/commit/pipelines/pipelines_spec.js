import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import mountComponent from 'helpers/vue_mount_component_helper';
import axios from '~/lib/utils/axios_utils';
import Api from '~/api';
import pipelinesTable from '~/commit/pipelines/pipelines_table.vue';

describe('Pipelines table in Commits and Merge requests', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';
  let pipeline;
  let PipelinesTable;
  let mock;
  let vm;
  const props = {
    endpoint: 'endpoint.json',
    helpPagePath: 'foo',
    emptyStateSvgPath: 'foo',
    errorStateSvgPath: 'foo',
    autoDevopsHelpPath: 'foo',
  };

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    mock = new MockAdapter(axios);

    const { pipelines } = getJSONFixture(jsonFixtureName);

    PipelinesTable = Vue.extend(pipelinesTable);
    pipeline = pipelines.find(p => p.user !== null && p.commit !== null);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('successful request', () => {
    describe('without pipelines', () => {
      beforeEach(() => {
        mock.onGet('endpoint.json').reply(200, []);

        vm = mountComponent(PipelinesTable, props);
      });

      it('should render the empty state', done => {
        setImmediate(() => {
          expect(vm.$el.querySelector('.empty-state')).toBeDefined();
          expect(vm.$el.querySelector('.realtime-loading')).toBe(null);
          expect(vm.$el.querySelector('.js-pipelines-error-state')).toBe(null);
          done();
        });
      });
    });

    describe('with pipelines', () => {
      beforeEach(() => {
        mock.onGet('endpoint.json').reply(200, [pipeline]);
        vm = mountComponent(PipelinesTable, props);
      });

      it('should render a table with the received pipelines', done => {
        setImmediate(() => {
          expect(vm.$el.querySelectorAll('.ci-table .commit').length).toEqual(1);
          expect(vm.$el.querySelector('.realtime-loading')).toBe(null);
          expect(vm.$el.querySelector('.empty-state')).toBe(null);
          expect(vm.$el.querySelector('.js-pipelines-error-state')).toBe(null);
          done();
        });
      });

      describe('with pagination', () => {
        it('should make an API request when using pagination', done => {
          setImmediate(() => {
            jest.spyOn(vm, 'updateContent').mockImplementation(() => {});

            vm.store.state.pageInfo = {
              page: 1,
              total: 10,
              perPage: 2,
              nextPage: 2,
              totalPages: 5,
            };

            vm.$nextTick(() => {
              vm.$el.querySelector('.next-page-item').click();

              expect(vm.updateContent).toHaveBeenCalledWith({ page: '2' });
              done();
            });
          });
        });
      });
    });

    describe('pipeline badge counts', () => {
      beforeEach(() => {
        mock.onGet('endpoint.json').reply(200, [pipeline]);
      });

      it('should receive update-pipelines-count event', done => {
        const element = document.createElement('div');
        document.body.appendChild(element);

        element.addEventListener('update-pipelines-count', event => {
          expect(event.detail.pipelines).toEqual([pipeline]);
          done();
        });

        vm = mountComponent(PipelinesTable, props);

        element.appendChild(vm.$el);
      });
    });
  });

  describe('run pipeline button', () => {
    let pipelineCopy;

    beforeEach(() => {
      pipelineCopy = { ...pipeline };
    });

    describe('when latest pipeline has detached flag and canRunPipeline is true', () => {
      it('renders the run pipeline button', done => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;
        pipelineCopy.flags.merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        vm = mountComponent(PipelinesTable, { ...props, canRunPipeline: true });

        setImmediate(() => {
          expect(vm.$el.querySelector('.js-run-mr-pipeline')).not.toBeNull();
          done();
        });
      });
    });

    describe('when latest pipeline has detached flag and canRunPipeline is false', () => {
      it('does not render the run pipeline button', done => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;
        pipelineCopy.flags.merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        vm = mountComponent(PipelinesTable, { ...props, canRunPipeline: false });

        setImmediate(() => {
          expect(vm.$el.querySelector('.js-run-mr-pipeline')).toBeNull();
          done();
        });
      });
    });

    describe('when latest pipeline does not have detached flag and canRunPipeline is true', () => {
      it('does not render the run pipeline button', done => {
        pipelineCopy.flags.detached_merge_request_pipeline = false;
        pipelineCopy.flags.merge_request_pipeline = false;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        vm = mountComponent(PipelinesTable, { ...props, canRunPipeline: true });

        setImmediate(() => {
          expect(vm.$el.querySelector('.js-run-mr-pipeline')).toBeNull();
          done();
        });
      });
    });

    describe('when latest pipeline does not have detached flag and merge_request_pipeline is true', () => {
      it('does not render the run pipeline button', done => {
        pipelineCopy.flags.detached_merge_request_pipeline = false;
        pipelineCopy.flags.merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        vm = mountComponent(PipelinesTable, { ...props, canRunPipeline: false });

        setImmediate(() => {
          expect(vm.$el.querySelector('.js-run-mr-pipeline')).toBeNull();
          done();
        });
      });
    });

    describe('on click', () => {
      beforeEach(() => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        vm = mountComponent(PipelinesTable, {
          ...props,
          canRunPipeline: true,
          projectId: '5',
          mergeRequestId: 3,
        });
      });

      it('updates the loading state', done => {
        jest.spyOn(Api, 'postMergeRequestPipeline').mockReturnValue(Promise.resolve());

        setImmediate(() => {
          vm.$el.querySelector('.js-run-mr-pipeline').click();

          vm.$nextTick(() => {
            expect(vm.state.isRunningMergeRequestPipeline).toBe(true);

            setImmediate(() => {
              expect(vm.state.isRunningMergeRequestPipeline).toBe(false);

              done();
            });
          });
        });
      });
    });
  });

  describe('unsuccessfull request', () => {
    beforeEach(() => {
      mock.onGet('endpoint.json').reply(500, []);

      vm = mountComponent(PipelinesTable, props);
    });

    it('should render error state', done => {
      setImmediate(() => {
        expect(vm.$el.querySelector('.js-pipelines-error-state')).toBeDefined();
        expect(vm.$el.querySelector('.realtime-loading')).toBe(null);
        expect(vm.$el.querySelector('.js-empty-state')).toBe(null);
        expect(vm.$el.querySelector('.ci-table')).toBe(null);
        done();
      });
    });
  });
});
