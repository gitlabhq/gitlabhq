import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { UPSTREAM, DOWNSTREAM } from '~/pipelines/components/graph/constants';
import LinkedPipelineComponent from '~/pipelines/components/graph/linked_pipeline.vue';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import mockData from './linked_pipelines_mock_data';

const mockPipeline = mockData.triggered[0];
const validTriggeredPipelineId = mockPipeline.project.id;
const invalidTriggeredPipelineId = mockPipeline.project.id + 5;

describe('Linked pipeline', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);
  const findDownstreamPipelineTitle = () => wrapper.find('[data-testid="downstream-title"]');
  const findPipelineLabel = () => wrapper.find('[data-testid="downstream-pipeline-label"]');
  const findLinkedPipeline = () => wrapper.find({ ref: 'linkedPipeline' });
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findPipelineLink = () => wrapper.find('[data-testid="pipelineLink"]');
  const findExpandButton = () => wrapper.find('[data-testid="expand-pipeline-button"]');

  const createWrapper = (propsData, data = []) => {
    wrapper = mount(LinkedPipelineComponent, {
      propsData,
      data() {
        return {
          ...data,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendered output', () => {
    const props = {
      pipeline: mockPipeline,
      projectId: invalidTriggeredPipelineId,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
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
      expect(wrapper.find('.ci-status-icon-failed svg').exists()).toBe(true);
    });

    it('should have a ci-status child component', () => {
      expect(wrapper.find(CiStatus).exists()).toBe(true);
    });

    it('should render the pipeline id', () => {
      expect(wrapper.text()).toContain(`#${props.pipeline.id}`);
    });

    it('should correctly compute the tooltip text', () => {
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.project.name);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.details.status.label);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.source_job.name);
      expect(wrapper.vm.tooltipText).toContain(mockPipeline.id);
    });

    it('should render the tooltip text as the title attribute', () => {
      const titleAttr = findLinkedPipeline().attributes('title');

      expect(titleAttr).toContain(mockPipeline.project.name);
      expect(titleAttr).toContain(mockPipeline.details.status.label);
    });

    it('sets the loading prop to false', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('should display multi-project label when pipeline project id is not the same as triggered pipeline project id', () => {
      expect(findPipelineLabel().text()).toBe('Multi-project');
    });
  });

  describe('parent/child', () => {
    const downstreamProps = {
      pipeline: mockPipeline,
      projectId: validTriggeredPipelineId,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
    };

    const upstreamProps = {
      ...downstreamProps,
      columnTitle: 'Upstream',
      type: UPSTREAM,
      expanded: false,
    };

    it('parent/child label container should exist', () => {
      createWrapper(downstreamProps);
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('should display child label when pipeline project id is the same as triggered pipeline project id', () => {
      createWrapper(downstreamProps);
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('should have the name of the trigger job on the card when it is a child pipeline', () => {
      createWrapper(downstreamProps);
      expect(findDownstreamPipelineTitle().text()).toBe(mockPipeline.source_job.name);
    });

    it('should display parent label when pipeline project id is the same as triggered_by pipeline project id', () => {
      createWrapper(upstreamProps);
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('downstream pipeline should contain the correct link', () => {
      createWrapper(downstreamProps);
      expect(findPipelineLink().attributes('href')).toBe(mockData.triggered_by.path);
    });

    it('upstream pipeline should contain the correct link', () => {
      createWrapper(upstreamProps);
      expect(findPipelineLink().attributes('href')).toBe(mockData.triggered_by.path);
    });

    it.each`
      presentClass        | missingClass
      ${'gl-right-0'}     | ${'gl-left-0'}
      ${'gl-border-l-1!'} | ${'gl-border-r-1!'}
    `(
      'pipeline expand button should be postioned right when child pipeline',
      ({ presentClass, missingClass }) => {
        createWrapper(downstreamProps);
        expect(findExpandButton().classes()).toContain(presentClass);
        expect(findExpandButton().classes()).not.toContain(missingClass);
      },
    );

    it.each`
      presentClass        | missingClass
      ${'gl-left-0'}      | ${'gl-right-0'}
      ${'gl-border-r-1!'} | ${'gl-border-l-1!'}
    `(
      'pipeline expand button should be postioned left when parent pipeline',
      ({ presentClass, missingClass }) => {
        createWrapper(upstreamProps);
        expect(findExpandButton().classes()).toContain(presentClass);
        expect(findExpandButton().classes()).not.toContain(missingClass);
      },
    );

    it.each`
      pipelineType       | anglePosition    | expanded
      ${downstreamProps} | ${'angle-right'} | ${false}
      ${downstreamProps} | ${'angle-left'}  | ${true}
      ${upstreamProps}   | ${'angle-left'}  | ${false}
      ${upstreamProps}   | ${'angle-right'} | ${true}
    `(
      '$pipelineType.columnTitle pipeline button icon should be $anglePosition if expanded state is $expanded',
      ({ pipelineType, anglePosition, expanded }) => {
        createWrapper({ ...pipelineType, expanded });
        expect(findExpandButton().props('icon')).toBe(anglePosition);
      },
    );
  });

  describe('when isLoading is true', () => {
    const props = {
      pipeline: { ...mockPipeline, isLoading: true },
      projectId: invalidTriggeredPipelineId,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
    };

    beforeEach(() => {
      createWrapper(props);
    });

    it('loading icon is visible', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('on click/hover', () => {
    const props = {
      pipeline: mockPipeline,
      projectId: validTriggeredPipelineId,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
    };

    beforeEach(() => {
      createWrapper(props);
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
      expect(wrapper.emitted().downstreamHovered).toStrictEqual([['trigger_job']]);
    });

    it('should emit downstreamHovered with empty string on mouseleave', () => {
      findLinkedPipeline().trigger('mouseleave');
      expect(wrapper.emitted().downstreamHovered).toStrictEqual([['']]);
    });

    it('should emit pipelineExpanded with job name and expanded state on click', () => {
      findExpandButton().trigger('click');
      expect(wrapper.emitted().pipelineExpandToggle).toStrictEqual([['trigger_job', true]]);
    });
  });
});
