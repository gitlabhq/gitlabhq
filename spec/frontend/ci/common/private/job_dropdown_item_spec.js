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
});
