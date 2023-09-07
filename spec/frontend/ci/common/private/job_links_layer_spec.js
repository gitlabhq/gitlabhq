import { shallowMount } from '@vue/test-utils';
import mockPipelineResponse from 'test_fixtures/pipelines/pipeline_details.json';
import LinksInner from '~/ci/pipeline_details/graph/components/links_inner.vue';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';

import { generateResponse } from 'jest/ci/pipeline_details/graph/mock_data';

describe('links layer component', () => {
  let wrapper;

  const findLinksInner = () => wrapper.findComponent(LinksInner);

  const pipeline = generateResponse(mockPipelineResponse, 'root/fungi-xoxo');
  const containerId = `pipeline-links-container-${pipeline.id}`;
  const slotContent = "<div>Ceci n'est pas un graphique</div>";

  const defaultProps = {
    containerId,
    containerMeasurements: { width: 400, height: 400 },
    pipelineId: pipeline.id,
    pipelineData: pipeline.stages,
    showLinks: false,
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

  describe('with show links off', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('does not render inner links component', () => {
      expect(findLinksInner().exists()).toBe(false);
    });
  });

  describe('with show links on', () => {
    beforeEach(() => {
      createComponent({
        props: {
          showLinks: true,
        },
      });
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('renders the inner links component', () => {
      expect(findLinksInner().exists()).toBe(true);
    });
  });

  describe('with width or height measurement at 0', () => {
    beforeEach(() => {
      createComponent({ props: { containerMeasurements: { width: 0, height: 100 } } });
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('does not render the inner links component', () => {
      expect(findLinksInner().exists()).toBe(false);
    });
  });
});
