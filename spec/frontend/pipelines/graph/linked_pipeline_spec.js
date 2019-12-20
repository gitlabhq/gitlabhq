import { mount } from '@vue/test-utils';
import LinkedPipelineComponent from '~/pipelines/components/graph/linked_pipeline.vue';

import mockData from './linked_pipelines_mock_data';

const mockPipeline = mockData.triggered[0];

describe('Linked pipeline', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendered output', () => {
    const props = {
      pipeline: mockPipeline,
    };

    beforeEach(() => {
      wrapper = mount(LinkedPipelineComponent, {
        sync: false,
        attachToDocument: true,
        propsData: props,
      });
    });

    it('should render a list item as the containing element', () => {
      expect(wrapper.is('li')).toBe(true);
    });

    it('should render a button', () => {
      const linkElement = wrapper.find('.js-linked-pipeline-content');

      expect(linkElement.exists()).toBe(true);
    });

    it('should render the project name', () => {
      expect(wrapper.text()).toContain(props.pipeline.project.name);
    });

    it('should render an svg within the status container', () => {
      const pipelineStatusElement = wrapper.find('.js-linked-pipeline-status');

      expect(pipelineStatusElement.find('svg').exists()).toBe(true);
    });

    it('should render the pipeline status icon svg', () => {
      expect(wrapper.find('.js-ci-status-icon-running').exists()).toBe(true);
      expect(wrapper.find('.js-ci-status-icon-running').html()).toContain('<svg');
    });

    it('should have a ci-status child component', () => {
      expect(wrapper.find('.js-linked-pipeline-status').exists()).toBe(true);
    });

    it('should render the pipeline id', () => {
      expect(wrapper.text()).toContain(`#${props.pipeline.id}`);
    });

    it('should correctly compute the tooltip text', () => {
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.project.name);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.details.status.label);
    });

    it('should render the tooltip text as the title attribute', () => {
      const tooltipRef = wrapper.find('.js-linked-pipeline-content');
      const titleAttr = tooltipRef.attributes('title');

      expect(titleAttr).toContain(mockPipeline.project.name);
      expect(titleAttr).toContain(mockPipeline.details.status.label);
    });

    it('does not render the loading icon when isLoading is false', () => {
      expect(wrapper.find('.js-linked-pipeline-loading').exists()).toBe(false);
    });
  });

  describe('when isLoading is true', () => {
    const props = {
      pipeline: { ...mockPipeline, isLoading: true },
    };

    beforeEach(() => {
      wrapper = mount(LinkedPipelineComponent, {
        sync: false,
        attachToDocument: true,
        propsData: props,
      });
    });

    it('renders a loading icon', () => {
      expect(wrapper.find('.js-linked-pipeline-loading').exists()).toBe(true);
    });
  });

  describe('on click', () => {
    const props = {
      pipeline: mockPipeline,
    };

    beforeEach(() => {
      wrapper = mount(LinkedPipelineComponent, {
        sync: false,
        attachToDocument: true,
        propsData: props,
      });
    });

    it('emits `pipelineClicked` event', () => {
      jest.spyOn(wrapper.vm, '$emit');
      wrapper.find('button').trigger('click');

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('pipelineClicked');
    });

    it('should emit `bv::hide::tooltip` to close the tooltip', () => {
      jest.spyOn(wrapper.vm.$root, '$emit');
      wrapper.find('button').trigger('click');

      expect(wrapper.vm.$root.$emit.mock.calls[0]).toEqual([
        'bv::hide::tooltip',
        'js-linked-pipeline-132',
      ]);
    });
  });
});
