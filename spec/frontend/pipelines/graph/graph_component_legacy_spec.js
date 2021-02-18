import { GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { setHTMLFixture } from 'helpers/fixtures';
import GraphComponentLegacy from '~/pipelines/components/graph/graph_component_legacy.vue';
import LinkedPipelinesColumnLegacy from '~/pipelines/components/graph/linked_pipelines_column_legacy.vue';
import StageColumnComponentLegacy from '~/pipelines/components/graph/stage_column_component_legacy.vue';
import PipelinesMediator from '~/pipelines/pipeline_details_mediator';
import PipelineStore from '~/pipelines/stores/pipeline_store';
import linkedPipelineJSON from './linked_pipelines_mock_data';
import graphJSON from './mock_data_legacy';

describe('graph component', () => {
  let store;
  let mediator;
  let wrapper;

  const findExpandPipelineBtn = () => wrapper.find('[data-testid="expand-pipeline-button"]');
  const findAllExpandPipelineBtns = () => wrapper.findAll('[data-testid="expand-pipeline-button"]');
  const findStageColumns = () => wrapper.findAll(StageColumnComponentLegacy);
  const findStageColumnAt = (i) => findStageColumns().at(i);

  beforeEach(() => {
    mediator = new PipelinesMediator({ endpoint: '' });
    store = new PipelineStore();
    store.storePipeline(linkedPipelineJSON);

    setHTMLFixture('<div class="layout-page"></div>');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('while is loading', () => {
    it('should render a loading icon', () => {
      wrapper = mount(GraphComponentLegacy, {
        propsData: {
          isLoading: true,
          pipeline: {},
          mediator,
        },
      });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = mount(GraphComponentLegacy, {
        propsData: {
          isLoading: false,
          pipeline: graphJSON,
          mediator,
        },
      });
    });

    it('renders the graph', () => {
      expect(wrapper.find('.js-pipeline-graph').exists()).toBe(true);
      expect(wrapper.find('.loading-icon').exists()).toBe(false);
      expect(wrapper.find('.stage-column-list').exists()).toBe(true);
    });

    it('renders columns in the graph', () => {
      expect(findStageColumns()).toHaveLength(graphJSON.details.stages.length);
    });
  });

  describe('when linked pipelines are present', () => {
    beforeEach(() => {
      wrapper = mount(GraphComponentLegacy, {
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
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      });

      it('should include the stage column', () => {
        expect(findStageColumnAt(0).exists()).toBe(true);
      });

      it('stage column should have no-margin, gl-mr-26, has-only-one-job classes if there is only one job', () => {
        expect(findStageColumnAt(0).classes()).toEqual(
          expect.arrayContaining(['no-margin', 'gl-mr-26', 'has-only-one-job']),
        );
      });

      it('should include the left-margin class on the second child', () => {
        expect(findStageColumnAt(1).classes('left-margin')).toBe(true);
      });

      it('should include the left-connector class in the build of the second child', () => {
        expect(findStageColumnAt(1).find('.build:nth-child(1)').classes('left-connector')).toBe(
          true,
        );
      });

      it('should include the js-has-linked-pipelines flag', () => {
        expect(wrapper.find('.js-has-linked-pipelines').exists()).toBe(true);
      });
    });

    describe('computeds and methods', () => {
      describe('capitalizeStageName', () => {
        it('it capitalizes the stage name', () => {
          expect(wrapper.findAll('.stage-column .stage-name').at(1).text()).toBe('Prebuild');
        });
      });

      describe('stageConnectorClass', () => {
        it('it returns left-margin when there is a triggerer', () => {
          expect(findStageColumnAt(1).classes('left-margin')).toBe(true);
        });
      });
    });

    describe('linked pipelines components', () => {
      beforeEach(() => {
        wrapper = mount(GraphComponentLegacy, {
          propsData: {
            isLoading: false,
            pipeline: store.state.pipeline,
            mediator,
          },
        });
      });

      it('should render an upstream pipelines column at first position', () => {
        expect(wrapper.find(LinkedPipelinesColumnLegacy).exists()).toBe(true);
        expect(wrapper.find('.stage-column .stage-name').text()).toBe('Upstream');
      });

      it('should render a downstream pipelines column at last position', () => {
        const stageColumnNames = wrapper.findAll('.stage-column .stage-name');

        expect(wrapper.find(LinkedPipelinesColumnLegacy).exists()).toBe(true);
        expect(stageColumnNames.at(stageColumnNames.length - 1).text()).toBe('Downstream');
      });

      describe('triggered by', () => {
        describe('on click', () => {
          it('should emit `onClickUpstreamPipeline` when triggered by linked pipeline is clicked', async () => {
            const btnWrapper = findExpandPipelineBtn();

            btnWrapper.trigger('click');

            await nextTick();
            expect(wrapper.emitted().onClickUpstreamPipeline).toEqual([
              store.state.pipeline.triggered_by,
            ]);
          });
        });

        describe('with expanded pipeline', () => {
          it('should render expanded pipeline', async () => {
            // expand the pipeline
            store.state.pipeline.triggered_by[0].isExpanded = true;

            wrapper = mount(GraphComponentLegacy, {
              propsData: {
                isLoading: false,
                pipeline: store.state.pipeline,
                mediator,
              },
            });

            await nextTick();
            expect(wrapper.find('.js-upstream-pipeline-12').exists()).toBe(true);
          });
        });
      });

      describe('triggered', () => {
        describe('on click', () => {
          // We have to mock this property of HTMLElement since component relies on it
          let offsetParentDescriptor;
          beforeAll(() => {
            offsetParentDescriptor = Object.getOwnPropertyDescriptor(
              HTMLElement.prototype,
              'offsetParent',
            );
            Object.defineProperty(HTMLElement.prototype, 'offsetParent', {
              get() {
                return this.parentNode;
              },
            });
          });
          afterAll(() => {
            Object.defineProperty(HTMLElement.prototype, offsetParentDescriptor);
          });

          it('should emit `onClickDownstreamPipeline`', async () => {
            const btnWrappers = findAllExpandPipelineBtns();
            const downstreamBtnWrapper = btnWrappers.at(btnWrappers.length - 1);

            downstreamBtnWrapper.trigger('click');

            await nextTick();
            expect(wrapper.emitted().onClickDownstreamPipeline).toEqual([
              [store.state.pipeline.triggered[1]],
            ]);
          });
        });

        describe('with expanded pipeline', () => {
          it('should render expanded pipeline', async () => {
            // expand the pipeline
            store.state.pipeline.triggered[0].isExpanded = true;

            wrapper = mount(GraphComponentLegacy, {
              propsData: {
                isLoading: false,
                pipeline: store.state.pipeline,
                mediator,
              },
            });

            await nextTick();
            expect(wrapper.find('.js-downstream-pipeline-34993051')).not.toBeNull();
          });
        });

        describe('when column requests a refresh', () => {
          beforeEach(() => {
            findStageColumnAt(0).vm.$emit('refreshPipelineGraph');
          });

          it('refreshPipelineGraph is emitted', () => {
            expect(wrapper.emitted().refreshPipelineGraph).toHaveLength(1);
          });
        });
      });
    });
  });

  describe('when linked pipelines are not present', () => {
    beforeEach(() => {
      const pipeline = Object.assign(linkedPipelineJSON, { triggered: null, triggered_by: null });
      wrapper = mount(GraphComponentLegacy, {
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

        expect(firstColumn.classes('no-margin')).toBe(true);
      });

      it('should not render a linked pipelines column', () => {
        expect(wrapper.find('.linked-pipelines-column').exists()).toBe(false);
      });
    });

    describe('stageConnectorClass', () => {
      it('it returns no-margin when no triggerer and there is one job', () => {
        expect(findStageColumnAt(0).classes('no-margin')).toBe(true);
      });

      it('it returns left-margin when no triggerer and not the first stage', () => {
        expect(findStageColumnAt(1).classes('left-margin')).toBe(true);
      });
    });
  });

  describe('capitalizeStageName', () => {
    it('capitalizes and escapes stage name', () => {
      wrapper = mount(GraphComponentLegacy, {
        propsData: {
          isLoading: false,
          pipeline: graphJSON,
          mediator,
        },
      });

      expect(findStageColumnAt(1).props('title')).toEqual(
        'Deploy &lt;img src=x onerror=alert(document.domain)&gt;',
      );
    });
  });
});
