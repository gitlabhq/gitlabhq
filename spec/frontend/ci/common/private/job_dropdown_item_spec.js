import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import JobActionButton from '~/ci/common/private/job_action_button.vue';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import JobNameComponent from '~/ci/common/private/job_name_component.vue';

import { mockPipelineJob } from '../../pipeline_mini_graph/mock_data';

const { detailedStatus, ...mockJobInfo } = mockPipelineJob;

const mockJobDetailedStatus = {
  ...mockJobInfo,
  detailedStatus,
};

const mockJobStatus = {
  ...mockJobInfo,
  status: detailedStatus,
};

describe('JobDropdownItem', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(JobDropdownItem, {
      propsData: {
        job: mockPipelineJob,
        ...props,
      },
    });
  };

  const findJobNameComponent = () => wrapper.findComponent(JobNameComponent);
  const findJobActionButton = () => wrapper.findComponent(JobActionButton);
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  describe.each([
    ['has detailedStatus', mockJobDetailedStatus],
    ['has status', mockJobStatus],
  ])('when job contains "%s"', (_, job) => {
    beforeEach(() => {
      createComponent({ props: { job } });
    });

    describe('job name', () => {
      it('renders the job name component', () => {
        expect(findJobNameComponent().exists()).toBe(true);
      });

      it('sends the necessary props to the job name component', () => {
        expect(findJobNameComponent().props()).toMatchObject({
          name: mockJobInfo.name,
          status: detailedStatus,
        });
      });

      it('sets the correct tooltip for the job item', () => {
        const tooltip = capitalizeFirstCharacter(detailedStatus.tooltip);

        expect(findJobNameComponent().attributes('title')).toBe(tooltip);
      });
    });

    describe('job action button', () => {
      describe('with a job action', () => {
        it('renders the job action button component', () => {
          expect(findJobActionButton().exists()).toBe(true);
        });

        it('sends the necessary props to the job action button', () => {
          expect(findJobActionButton().props()).toMatchObject({
            jobId: mockJobInfo.id,
            jobAction: detailedStatus.action,
            jobName: mockJobInfo.name,
          });
        });

        it('emits jobActionExecuted', () => {
          findJobActionButton().vm.$emit('jobActionExecuted');
          expect(wrapper.emitted('jobActionExecuted')).toHaveLength(1);
        });
      });
    });
  });

  describe('job status', () => {
    it.each`
      statusGroup  | shouldHaveFailedClass
      ${'success'} | ${false}
      ${'failed'}  | ${true}
    `(
      'when status is $statusGroup, failed class presence should be $shouldHaveFailedClass',
      ({ statusGroup, shouldHaveFailedClass }) => {
        const failedJob = {
          ...mockJobInfo,
          detailedStatus: {
            ...detailedStatus,
            group: statusGroup,
          },
        };

        createComponent({ props: { job: failedJob } });

        expect(wrapper.classes().includes('ci-job-item-failed')).toBe(shouldHaveFailedClass);
      },
    );
  });

  describe('details path', () => {
    it('should use detailed status details path by default', () => {
      createComponent({ props: { job: mockJobDetailedStatus } });

      expect(findDropdownItem().props('item').href).toBe(detailedStatus.detailsPath);
    });

    it('should use deployment details path for manual bridge jobs', () => {
      const bridgeJob = {
        ...mockJobInfo,
        detailedStatus: {
          ...detailedStatus,
          detailsPath: '',
          deploymentDetailsPath: 'path/to/deployment',
        },
      };
      createComponent({ props: { job: bridgeJob } });

      expect(findDropdownItem().props('item').href).toBe('path/to/deployment');
    });

    it('should not render a link if the details path and deployment details path are missing', () => {
      const noLinkJob = {
        ...mockJobInfo,
        detailedStatus: {
          ...detailedStatus,
          detailsPath: '',
          deploymentDetailsPath: '',
        },
      };
      createComponent({ props: { job: noLinkJob } });

      expect(findDropdownItem().props('item').href).toBe('');
    });
  });

  describe('unauthorized manual action', () => {
    describe('when user is not authorized to run manual job', () => {
      const unauthorizedJob = {
        ...mockJobInfo,
        detailedStatus: {
          ...detailedStatus,
          action: null,
          group: 'manual',
          label: 'manual play action (not allowed)',
        },
      };

      beforeEach(() => {
        createComponent({ props: { job: unauthorizedJob } });
      });

      it('renders a disabled job action button', () => {
        expect(findJobActionButton().props('disabled')).toBe(true);
      });

      it('provides the correct data for jobAction', () => {
        expect(findJobActionButton().props('jobAction')).toEqual({
          title: 'You are not authorized to run this manual job',
          icon: 'play',
          confirmationMessage: null,
        });
      });
    });
  });
});
