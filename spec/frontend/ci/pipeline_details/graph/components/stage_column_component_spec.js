import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import JobItem from '~/ci/pipeline_details/graph/components/job_item.vue';
import StageColumnComponent from '~/ci/pipeline_details/graph/components/stage_column_component.vue';
import ActionComponent from '~/ci/common/private/job_action_component.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

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

  afterEach(() => {
    confirmAction.mockReset();
  });

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
              jobs: [mockJob],
              name: 'test',
              size: 1,
              title: 'Fish',
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
        confirmationMessage: null,
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

    describe('confirmation modal', () => {
      it('not render modal when action is clicked and stage has no confirmation message', async () => {
        const mock = new MockAdapter(axios);
        createComponent({
          method: mount,
          props: {
            ...defaults,
          },
        });

        findActionComponent().trigger('click');
        await waitForPromises();

        expect(confirmAction).not.toHaveBeenCalled();
        expect(mock.history.post[0].url).toBe('action.json');
      });

      describe('stage has confirmation message', () => {
        const stageWithConfirmationMessage = JSON.parse(JSON.stringify(defaults));
        const confirmationMessage = 'Please Confirm';
        stageWithConfirmationMessage.action.confirmationMessage = confirmationMessage;
        stageWithConfirmationMessage.name = 'Manual Stage';

        it('render modal when action is clicked and stage has confirmation message', () => {
          createComponent({
            method: mount,
            props: {
              ...stageWithConfirmationMessage,
            },
          });
          findActionComponent().trigger('click');

          expect(confirmAction).toHaveBeenCalledWith(
            null,
            expect.objectContaining({
              primaryBtnText: `Yes, run all manual`,
              title: `Are you sure you want to run ${stageWithConfirmationMessage.name}?`,
              modalHtmlMessage: expect.stringContaining(confirmationMessage),
            }),
          );
        });

        it('execute post action modal is confirmed', async () => {
          createComponent({
            method: mount,
            props: {
              ...stageWithConfirmationMessage,
            },
          });
          confirmAction.mockResolvedValue(true);
          const mock = new MockAdapter(axios);

          findActionComponent().trigger('click');

          await waitForPromises();
          expect(mock.history.post[0].url).toBe('action.json');
        });
      });
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
