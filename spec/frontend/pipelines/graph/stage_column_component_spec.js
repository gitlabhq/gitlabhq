import { mount, shallowMount } from '@vue/test-utils';
import JobItem from '~/ci/pipeline_details/graph/components/job_item.vue';
import StageColumnComponent from '~/ci/pipeline_details/graph/components/stage_column_component.vue';
import ActionComponent from '~/ci/common/private/job_action_component.vue';

const mockJob = {
  id: 4250,
  name: 'test',
  status: {
    icon: 'status_success',
    text: 'passed',
    label: 'passed',
    group: 'success',
    details_path: '/root/ci-mock/builds/4250',
    action: {
      icon: 'retry',
      title: 'Retry',
      path: '/root/ci-mock/builds/4250/retry',
      method: 'post',
    },
  },
};

const mockGroups = Array(4)
  .fill(0)
  .map((item, idx) => {
    return { ...mockJob, jobs: [mockJob], id: idx, name: `fish-${idx}` };
  });

const defaultProps = {
  name: 'Fish',
  groups: mockGroups,
  pipelineId: 159,
  userPermissions: {
    updatePipeline: true,
  },
};

describe('stage column component', () => {
  let wrapper;

  const findStageColumnTitle = () => wrapper.find('[data-testid="stage-column-title"]');
  const findStageColumnGroup = () => wrapper.find('[data-testid="stage-column-group"]');
  const findAllStageColumnGroups = () => wrapper.findAll('[data-testid="stage-column-group"]');
  const findJobItem = () => wrapper.findComponent(JobItem);
  const findActionComponent = () => wrapper.findComponent(ActionComponent);

  const createComponent = ({ method = shallowMount, props = {} } = {}) => {
    wrapper = method(StageColumnComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent({ method: mount });
    });

    it('should render provided title', () => {
      expect(findStageColumnTitle().text()).toBe(defaultProps.name);
    });

    it('should render the provided groups', () => {
      expect(findAllStageColumnGroups().length).toBe(mockGroups.length);
    });

    it('should emit updateMeasurements event on mount', () => {
      expect(wrapper.emitted().updateMeasurements).toHaveLength(1);
    });
  });

  describe('when job notifies action is complete', () => {
    beforeEach(() => {
      createComponent({
        method: mount,
        props: {
          groups: [
            {
              title: 'Fish',
              size: 1,
              jobs: [mockJob],
            },
          ],
        },
      });
      findJobItem().vm.$emit('pipelineActionRequestComplete');
    });

    it('emits refreshPipelineGraph', () => {
      expect(wrapper.emitted().refreshPipelineGraph).toHaveLength(1);
    });
  });

  describe('job', () => {
    describe('text handling', () => {
      beforeEach(() => {
        createComponent({
          method: mount,
          props: {
            groups: [
              {
                ...mockJob,
                name: '<img src=x onerror=alert(document.domain)>',
                jobs: [
                  {
                    id: 4259,
                    name: '<img src=x onerror=alert(document.domain)>',
                    status: {
                      icon: 'status_success',
                      label: 'success',
                      tooltip: '<img src=x onerror=alert(document.domain)>',
                    },
                  },
                ],
              },
            ],
            name: 'test <img src=x onerror=alert(document.domain)>',
          },
        });
      });

      it('escapes name', () => {
        expect(findStageColumnTitle().html()).toContain(
          'test &lt;img src=x onerror=alert(document.domain)&gt;',
        );
      });

      it('escapes id', () => {
        expect(findStageColumnGroup().attributes('id')).toBe(
          'ci-badge-&lt;img src=x onerror=alert(document.domain)&gt;',
        );
      });
    });

    describe('interactions', () => {
      beforeEach(() => {
        createComponent({ method: mount });
      });

      it('emits jobHovered event on mouseenter and mouseleave', async () => {
        await findStageColumnGroup().trigger('mouseenter');
        expect(wrapper.emitted().jobHover).toEqual([[defaultProps.groups[0].name]]);
        await findStageColumnGroup().trigger('mouseleave');
        expect(wrapper.emitted().jobHover).toEqual([[defaultProps.groups[0].name], ['']]);
      });
    });
  });

  describe('with action', () => {
    const defaults = {
      groups: [
        {
          id: 4259,
          name: '<img src=x onerror=alert(document.domain)>',
          status: {
            icon: 'status_success',
            label: 'success',
            tooltip: '<img src=x onerror=alert(document.domain)>',
          },
          jobs: [mockJob],
        },
      ],
      title: 'test',
      hasTriggeredBy: false,
      action: {
        icon: 'play',
        title: 'Play all',
        path: 'action',
      },
    };

    it('renders action button if permissions are permitted', () => {
      createComponent({
        method: mount,
        props: {
          ...defaults,
        },
      });

      expect(findActionComponent().exists()).toBe(true);
    });

    it('does not render action button if permissions are not permitted', () => {
      createComponent({
        method: mount,
        props: {
          ...defaults,
          userPermissions: {
            updatePipeline: false,
          },
        },
      });

      expect(findActionComponent().exists()).toBe(false);
    });
  });

  describe('without action', () => {
    beforeEach(() => {
      createComponent({
        method: mount,
        props: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
              jobs: [mockJob],
            },
          ],
          title: 'test',
          hasTriggeredBy: false,
        },
      });
    });

    it('does not render action button', () => {
      expect(findActionComponent().exists()).toBe(false);
    });
  });
});
