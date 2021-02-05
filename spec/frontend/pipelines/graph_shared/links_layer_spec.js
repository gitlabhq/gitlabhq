import { mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlButton } from '@gitlab/ui';
import LinksLayer from '~/pipelines/components/graph_shared/links_layer.vue';
import LinksInner from '~/pipelines/components/graph_shared/links_inner.vue';
import { generateResponse, mockPipelineResponse } from '../graph/mock_data';

describe('links layer component', () => {
  let wrapper;

  const findAlert = () => wrapper.find(GlAlert);
  const findShowAnyways = () => findAlert().find(GlButton);
  const findLinksInner = () => wrapper.find(LinksInner);

  const pipeline = generateResponse(mockPipelineResponse, 'root/fungi-xoxo');
  const containerId = `pipeline-links-container-${pipeline.id}`;
  const slotContent = "<div>Ceci n'est pas un graphique</div>";

  const tooManyStages = Array(101)
    .fill(0)
    .flatMap(() => pipeline.stages);

  const defaultProps = {
    containerId,
    containerMeasurements: { width: 400, height: 400 },
    pipelineId: pipeline.id,
    pipelineData: pipeline.stages,
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(LinksLayer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      slots: {
        default: slotContent,
      },
      stubs: {
        'links-inner': true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with data under max stages', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('renders the inner links component', () => {
      expect(findLinksInner().exists()).toBe(true);
    });
  });

  describe('with more than the max number of stages', () => {
    describe('rendering', () => {
      beforeEach(() => {
        createComponent({ props: { pipelineData: tooManyStages } });
      });

      it('renders the default slot', () => {
        expect(wrapper.html()).toContain(slotContent);
      });

      it('renders the alert component', () => {
        expect(findAlert().exists()).toBe(true);
      });

      it('does not render the inner links component', () => {
        expect(findLinksInner().exists()).toBe(false);
      });
    });

    describe('interactions', () => {
      beforeEach(() => {
        createComponent({ mountFn: mount, props: { pipelineData: tooManyStages } });
      });

      it('renders the disable button', () => {
        expect(findShowAnyways().exists()).toBe(true);
        expect(findShowAnyways().text()).toBe(wrapper.vm.$options.i18n.showLinksAnyways);
      });

      it('shows links when override is clicked', async () => {
        expect(findLinksInner().exists()).toBe(false);
        await findShowAnyways().trigger('click');
        expect(findLinksInner().exists()).toBe(true);
      });
    });
  });
});
