import { mount } from '@vue/test-utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LinkedPipelinesMiniList from '~/ci/pipeline_mini_graph/linked_pipelines_mini_list.vue';
import mockData from './linked_pipelines_mock_data';

describe('Linked pipeline mini list', () => {
  let wrapper;

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findCiIcons = () => wrapper.findAllComponents(CiIcon);
  const findLinkedPipelineCounter = () => wrapper.find('[data-testid="linked-pipeline-counter"]');
  const findLinkedPipelineMiniItem = () =>
    wrapper.find('[data-testid="linked-pipeline-mini-item"]');
  const findLinkedPipelineMiniItems = () =>
    wrapper.findAll('[data-testid="linked-pipeline-mini-item"]');
  const findLinkedPipelineMiniList = () => wrapper.findComponent(LinkedPipelinesMiniList);

  const createComponent = (props = {}) => {
    wrapper = mount(LinkedPipelinesMiniList, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...props,
      },
    });
  };

  describe('when passed an upstream pipeline as prop', () => {
    beforeEach(() => {
      createComponent({
        triggeredBy: [mockData.triggered_by],
      });
    });

    it('should render one linked pipeline item', () => {
      expect(findLinkedPipelineMiniItem().exists()).toBe(true);
    });

    it('should render a linked pipeline with the correct href', () => {
      expect(findLinkedPipelineMiniItem().exists()).toBe(true);

      expect(findLinkedPipelineMiniItem().attributes('href')).toBe(
        '/gitlab-org/gitlab-foss/-/pipelines/129',
      );
    });

    it('should render one ci status icon', () => {
      expect(findCiIcon().exists()).toBe(true);
    });

    it('should render the correct ci status icon', () => {
      expect(wrapper.find('[data-testid="status_running_borderless-icon"]').exists()).toBe(true);
    });

    it('should have an activated tooltip', () => {
      expect(findLinkedPipelineMiniItem().exists()).toBe(true);
      const tooltip = getBinding(findLinkedPipelineMiniItem().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe('GitLabCE - running');
    });

    it('should correctly set is-upstream', () => {
      expect(findLinkedPipelineMiniList().exists()).toBe(true);

      expect(findLinkedPipelineMiniList().classes('is-upstream')).toBe(true);
    });

    it('should correctly compute shouldRenderCounter', () => {
      expect(findLinkedPipelineMiniList().vm.shouldRenderCounter).toBe(false);
    });

    it('should not render the pipeline counter', () => {
      expect(findLinkedPipelineCounter().exists()).toBe(false);
    });
  });

  describe('when passed downstream pipelines as props', () => {
    beforeEach(() => {
      createComponent({
        triggered: mockData.triggered,
        pipelinePath: 'my/pipeline/path',
      });
    });

    it('should render three linked pipeline items', () => {
      expect(findLinkedPipelineMiniItems().exists()).toBe(true);
      expect(findLinkedPipelineMiniItems().length).toBe(3);
    });

    it('should render three ci status icons', () => {
      expect(findCiIcons().exists()).toBe(true);
      expect(findCiIcons().length).toBe(3);
    });

    it('should render the correct ci status icon', () => {
      expect(wrapper.find('[data-testid="status_running_borderless-icon"]').exists()).toBe(true);
    });

    it('should have an activated tooltip', () => {
      expect(findLinkedPipelineMiniItem().exists()).toBe(true);
      const tooltip = getBinding(findLinkedPipelineMiniItem().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe('GitLabCE - running');
    });

    it('should correctly set is-downstream', () => {
      expect(findLinkedPipelineMiniList().exists()).toBe(true);

      expect(findLinkedPipelineMiniList().classes('is-downstream')).toBe(true);
    });

    it('should render the pipeline counter', () => {
      expect(findLinkedPipelineCounter().exists()).toBe(true);
    });

    it('should correctly compute shouldRenderCounter', () => {
      expect(findLinkedPipelineMiniList().vm.shouldRenderCounter).toBe(true);
    });

    it('should correctly trim linkedPipelines', () => {
      expect(findLinkedPipelineMiniList().props('triggered').length).toBe(6);
      expect(findLinkedPipelineMiniList().vm.linkedPipelinesTrimmed.length).toBe(3);
    });

    it('should set the correct pipeline path', () => {
      expect(findLinkedPipelineCounter().exists()).toBe(true);

      expect(findLinkedPipelineCounter().attributes('href')).toBe('my/pipeline/path');
    });

    it('should render the correct counterTooltipText', () => {
      expect(findLinkedPipelineCounter().exists()).toBe(true);
      const tooltip = getBinding(findLinkedPipelineCounter().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe(findLinkedPipelineMiniList().vm.counterTooltipText);
    });
  });
});
