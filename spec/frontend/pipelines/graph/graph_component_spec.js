import Vue from 'vue';
import { mount } from '@vue/test-utils';
import PipelineStore from '~/pipelines/stores/pipeline_store';
import graphComponent from '~/pipelines/components/graph/graph_component.vue';
import stageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import linkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import graphJSON from './mock_data';
import linkedPipelineJSON from './linked_pipelines_mock_data';
import PipelinesMediator from '~/pipelines/pipeline_details_mediator';
import { setHTMLFixture } from 'helpers/fixtures';

describe('graph component', () => {
  const store = new PipelineStore();
  store.storePipeline(linkedPipelineJSON);
  const mediator = new PipelinesMediator({ endpoint: '' });

  let wrapper;

  beforeEach(() => {
    setHTMLFixture('<div class="layout-page"></div>');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: true,
          pipeline: {},
          mediator,
        },
      });

      expect(wrapper.find('.gl-spinner').exists()).toBe(true);
    });
  });

  describe('with data', () => {
    it('should render the graph', () => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline: graphJSON,
          mediator,
        },
      });

      expect(wrapper.find('.js-pipeline-graph').exists()).toBe(true);

      expect(wrapper.find(stageColumnComponent).classes()).toContain('no-margin');

      expect(
        wrapper
          .findAll(stageColumnComponent)
          .at(1)
          .classes(),
      ).toContain('left-margin');

      expect(wrapper.find('.stage-column:nth-child(2) .build:nth-child(1)').classes()).toContain(
        'left-connector',
      );

      expect(wrapper.find('.loading-icon').exists()).toBe(false);

      expect(wrapper.find('.stage-column-list').exists()).toBe(true);
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline: store.state.pipeline,
          mediator,
        },
      });
    });

    describe('rendered output', () => {
      it('should include the pipelines graph', () => {
        expect(wrapper.find('.js-pipeline-graph').exists()).toBe(true);
      });

      it('should not include the loading icon', () => {
        expect(wrapper.find('.fa-spinner').exists()).toBe(false);
      });

      it('should include the stage column list', () => {
        expect(wrapper.find(stageColumnComponent).exists()).toBe(true);
      });

      it('should include the no-margin class on the first child if there is only one job', () => {
        const firstStageColumnElement = wrapper.find(stageColumnComponent);

        expect(firstStageColumnElement.classes()).toContain('no-margin');
      });

      it('should include the has-only-one-job class on the first child', () => {
        const firstStageColumnElement = wrapper.find('.stage-column-list .stage-column');

        expect(firstStageColumnElement.classes()).toContain('has-only-one-job');
      });

      it('should include the left-margin class on the second child', () => {
        const firstStageColumnElement = wrapper.find('.stage-column-list .stage-column:last-child');

        expect(firstStageColumnElement.classes()).toContain('left-margin');
      });

      it('should include the js-has-linked-pipelines flag', () => {
        expect(wrapper.find('.js-has-linked-pipelines').exists()).toBe(true);
      });
    });

    describe('computeds and methods', () => {
      describe('capitalizeStageName', () => {
        it('it capitalizes the stage name', () => {
          expect(
            wrapper
              .findAll('.stage-column .stage-name')
              .at(1)
              .text(),
          ).toBe('Prebuild');
        });
      });

      describe('stageConnectorClass', () => {
        it('it returns left-margin when there is a triggerer', () => {
          expect(
            wrapper
              .findAll(stageColumnComponent)
              .at(1)
              .classes(),
          ).toContain('left-margin');
        });
      });
    });

    describe('linked pipelines components', () => {
      beforeEach(() => {
        wrapper = mount(graphComponent, {
          propsData: {
            isLoading: false,
            pipeline: store.state.pipeline,
            mediator,
          },
        });
      });

      it('should render an upstream pipelines column at first position', () => {
        expect(wrapper.find(linkedPipelinesColumn).exists()).toBe(true);
        expect(wrapper.find('.stage-column .stage-name').text()).toBe('Upstream');
      });

      it('should render a downstream pipelines column at last position', () => {
        const stageColumnNames = wrapper.findAll('.stage-column .stage-name');

        expect(wrapper.find(linkedPipelinesColumn).exists()).toBe(true);
        expect(stageColumnNames.at(stageColumnNames.length - 1).text()).toBe('Downstream');
      });

      describe('triggered by', () => {
        describe('on click', () => {
          it('should emit `onClickTriggeredBy` when triggered by linked pipeline is clicked', () => {
            const btnWrapper = wrapper.find('.linked-pipeline-content');

            btnWrapper.trigger('click');

            btnWrapper.vm.$nextTick(() => {
              expect(wrapper.emitted().onClickTriggeredBy).toEqual([
                store.state.pipeline.triggered_by,
              ]);
            });
          });
        });

        describe('with expanded pipeline', () => {
          it('should render expanded pipeline', done => {
            // expand the pipeline
            store.state.pipeline.triggered_by[0].isExpanded = true;

            wrapper = mount(graphComponent, {
              propsData: {
                isLoading: false,
                pipeline: store.state.pipeline,
                mediator,
              },
            });

            Vue.nextTick()
              .then(() => {
                expect(wrapper.find('.js-upstream-pipeline-12').exists()).toBe(true);
              })
              .then(done)
              .catch(done.fail);
          });
        });
      });

      describe('triggered', () => {
        describe('on click', () => {
          it('should emit `onClickTriggered`', () => {
            // We have to mock this method since we do both style change and
            // emit and event, not mocking returns an error.
            wrapper.setMethods({
              handleClickedDownstream: jest.fn(() =>
                wrapper.vm.$emit('onClickTriggered', ...store.state.pipeline.triggered),
              ),
            });

            const btnWrappers = wrapper.findAll('.linked-pipeline-content');
            const downstreamBtnWrapper = btnWrappers.at(btnWrappers.length - 1);

            downstreamBtnWrapper.trigger('click');

            downstreamBtnWrapper.vm.$nextTick(() => {
              expect(wrapper.emitted().onClickTriggered).toEqual([store.state.pipeline.triggered]);
            });
          });
        });

        describe('with expanded pipeline', () => {
          it('should render expanded pipeline', done => {
            // expand the pipeline
            store.state.pipeline.triggered[0].isExpanded = true;

            wrapper = mount(graphComponent, {
              propsData: {
                isLoading: false,
                pipeline: store.state.pipeline,
                mediator,
              },
            });

            Vue.nextTick()
              .then(() => {
                expect(wrapper.find('.js-downstream-pipeline-34993051')).not.toBeNull();
              })
              .then(done)
              .catch(done.fail);
          });
        });
      });
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      const pipeline = Object.assign(linkedPipelineJSON, { triggered: null, triggered_by: null });
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline,
          mediator,
        },
      });
    });

    describe('rendered output', () => {
      it('should include the first column with a no margin', () => {
        const firstColumn = wrapper.find('.stage-column');

        expect(firstColumn.classes()).toContain('no-margin');
      });

      it('should not render a linked pipelines column', () => {
        expect(wrapper.find('.linked-pipelines-column').exists()).toBe(false);
      });
    });

    describe('stageConnectorClass', () => {
      it('it returns no-margin when no triggerer and there is one job', () => {
        expect(wrapper.find(stageColumnComponent).classes()).toContain('no-margin');
      });

      it('it returns left-margin when no triggerer and not the first stage', () => {
        expect(
          wrapper
            .findAll(stageColumnComponent)
            .at(1)
            .classes(),
        ).toContain('left-margin');
      });
    });
  });

  describe('capitalizeStageName', () => {
    it('capitalizes and escapes stage name', () => {
      wrapper = mount(graphComponent, {
        propsData: {
          isLoading: false,
          pipeline: graphJSON,
          mediator,
        },
      });

      expect(
        wrapper
          .find('.stage-column:nth-child(2) .stage-name')
          .text()
          .trim(),
      ).toEqual('Deploy &lt;img src=x onerror=alert(document.domain)&gt;');
    });
  });
});
