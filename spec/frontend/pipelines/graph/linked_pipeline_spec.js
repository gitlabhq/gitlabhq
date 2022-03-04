import { GlButton, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { UPSTREAM, DOWNSTREAM } from '~/pipelines/components/graph/constants';
import LinkedPipelineComponent from '~/pipelines/components/graph/linked_pipeline.vue';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import mockPipeline from './linked_pipelines_mock_data';

describe('Linked pipeline', () => {
  let wrapper;

  const defaultProps = {
    pipeline: mockPipeline,
    columnTitle: 'Downstream',
    type: DOWNSTREAM,
    expanded: false,
    isLoading: false,
    isMultiProjectVizAvailable: true,
  };

  const downstreamProps = {
    pipeline: {
      ...mockPipeline,
      multiproject: false,
    },
  };

  const upstreamProps = {
    ...downstreamProps,
    columnTitle: 'Upstream',
    type: UPSTREAM,
  };

  const findButton = () => wrapper.find(GlButton);
  const findDownstreamPipelineTitle = () => wrapper.findByTestId('downstream-title');
  const findPipelineLabel = () => wrapper.findByTestId('downstream-pipeline-label');
  const findLinkedPipeline = () => wrapper.findByTestId('linkedPipeline');
  const findLinkedPipelineBody = () => wrapper.findByTestId('linkedPipelineBody');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findPipelineLink = () => wrapper.findByTestId('pipelineLink');
  const findExpandButton = () => wrapper.findByTestId('expand-pipeline-button');
  const findPopover = () => wrapper.find(GlPopover);

  const createWrapper = (propsData, data = []) => {
    wrapper = mountExtended(LinkedPipelineComponent, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      data() {
        return {
          ...data,
        };
      },
      provide: {
        multiProjectHelpPath: '/ci/pipelines/multi-project-pipelines',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendered output', () => {
    const props = {
      pipeline: mockPipeline,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
      isLoading: false,
    };

    beforeEach(() => {
      createWrapper(props);
    });

    it('should render the project name', () => {
      expect(wrapper.text()).toContain(props.pipeline.project.name);
    });

    it('should render an svg within the status container', () => {
      const pipelineStatusElement = wrapper.find(CiStatus);

      expect(pipelineStatusElement.find('svg').exists()).toBe(true);
    });

    it('should render the pipeline status icon svg', () => {
      expect(wrapper.find('.ci-status-icon-success svg').exists()).toBe(true);
    });

    it('should have a ci-status child component', () => {
      expect(wrapper.find(CiStatus).exists()).toBe(true);
    });

    it('should render the pipeline id', () => {
      expect(wrapper.text()).toContain(`#${props.pipeline.id}`);
    });

    it('should correctly compute the tooltip text', () => {
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.project.name);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.status.label);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.sourceJob.name);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.id);
    });

    it('should render the tooltip text as the title attribute', () => {
      const titleAttr = findLinkedPipelineBody().attributes('title');

      expect(titleAttr).toContain(mockPipeline.project.name);
      expect(titleAttr).toContain(mockPipeline.status.label);
    });

    it('should display multi-project label when pipeline project id is not the same as triggered pipeline project id', () => {
      expect(findPipelineLabel().text()).toBe('Multi-project');
    });
  });

  describe('upstream pipelines', () => {
    beforeEach(() => {
      createWrapper(upstreamProps);
    });

    it('should display parent label when pipeline project id is the same as triggered_by pipeline project id', () => {
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('upstream pipeline should contain the correct link', () => {
      expect(findPipelineLink().attributes('href')).toBe(upstreamProps.pipeline.path);
    });

    it('applies the reverse-row css class to the card', () => {
      expect(findLinkedPipeline().classes()).toContain('gl-flex-direction-row-reverse');
      expect(findLinkedPipeline().classes()).not.toContain('gl-flex-direction-row');
    });
  });

  describe('downstream pipelines', () => {
    beforeEach(() => {
      createWrapper(downstreamProps);
    });

    it('parent/child label container should exist', () => {
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('should display child label when pipeline project id is the same as triggered pipeline project id', () => {
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('should have the name of the trigger job on the card when it is a child pipeline', () => {
      expect(findDownstreamPipelineTitle().text()).toBe(mockPipeline.sourceJob.name);
    });

    it('downstream pipeline should contain the correct link', () => {
      expect(findPipelineLink().attributes('href')).toBe(downstreamProps.pipeline.path);
    });

    it('applies the flex-row css class to the card', () => {
      expect(findLinkedPipeline().classes()).toContain('gl-flex-direction-row');
      expect(findLinkedPipeline().classes()).not.toContain('gl-flex-direction-row-reverse');
    });
  });

  describe('expand button', () => {
    it.each`
      pipelineType       | anglePosition    | borderClass         | expanded
      ${downstreamProps} | ${'angle-right'} | ${'gl-border-l-1!'} | ${false}
      ${downstreamProps} | ${'angle-left'}  | ${'gl-border-l-1!'} | ${true}
      ${upstreamProps}   | ${'angle-left'}  | ${'gl-border-r-1!'} | ${false}
      ${upstreamProps}   | ${'angle-right'} | ${'gl-border-r-1!'} | ${true}
    `(
      '$pipelineType.columnTitle pipeline button icon should be $anglePosition with $borderClass if expanded state is $expanded',
      ({ pipelineType, anglePosition, borderClass, expanded }) => {
        createWrapper({ ...pipelineType, expanded });
        expect(findExpandButton().props('icon')).toBe(anglePosition);
        expect(findExpandButton().classes()).toContain(borderClass);
      },
    );
  });

  describe('when isLoading is true', () => {
    const props = {
      isLoading: true,
    };

    beforeEach(() => {
      createWrapper(props);
    });

    it('loading icon is visible', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when the user does not have access to the multi-project pipeline viz feature', () => {
    beforeEach(() => {
      const props = { isMultiProjectVizAvailable: false };
      createWrapper(props);
    });

    it('the multi-project expand button is disabled', () => {
      expect(findExpandButton().props('disabled')).toBe(true);
    });

    it('it adds the popover text inside the DOM', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().text()).toContain(
        'Gitlab Premium users have access to the multi-project pipeline graph to improve the visualization of these pipelines.',
      );
    });
  });

  describe('when the user has access to the multi-project pipeline viz feature', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('the multi-project expand button is enabled', () => {
      expect(findExpandButton().props('disabled')).toBe(false);
    });

    it('does not add the popover text inside the DOM', () => {
      expect(findPopover().exists()).toBe(false);
    });
  });

  describe('on click/hover', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('emits `pipelineClicked` event', () => {
      jest.spyOn(wrapper.vm, '$emit');
      findButton().trigger('click');

      expect(wrapper.emitted().pipelineClicked).toBeTruthy();
    });

    it(`should emit ${BV_HIDE_TOOLTIP} to close the tooltip`, () => {
      jest.spyOn(wrapper.vm.$root, '$emit');
      findButton().trigger('click');

      expect(wrapper.vm.$root.$emit.mock.calls[0]).toEqual([BV_HIDE_TOOLTIP]);
    });

    it('should emit downstreamHovered with job name on mouseover', () => {
      findLinkedPipeline().trigger('mouseover');
      expect(wrapper.emitted().downstreamHovered).toStrictEqual([['test_c']]);
    });

    it('should emit downstreamHovered with empty string on mouseleave', () => {
      findLinkedPipeline().trigger('mouseleave');
      expect(wrapper.emitted().downstreamHovered).toStrictEqual([['']]);
    });

    it('should emit pipelineExpanded with job name and expanded state on click', () => {
      findExpandButton().trigger('click');
      expect(wrapper.emitted().pipelineExpandToggle).toStrictEqual([['test_c', true]]);
    });
  });
});
