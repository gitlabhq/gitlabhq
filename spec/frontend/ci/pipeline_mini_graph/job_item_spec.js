import { shallowMount } from '@vue/test-utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import JobActionButton from '~/ci/pipeline_mini_graph/job_action_button.vue';
import JobItem from '~/ci/pipeline_mini_graph/job_item.vue';
import JobNameComponent from '~/ci/common/private/job_name_component.vue';

import { mockPipelineJob } from './mock_data';

describe('JobItem', () => {
  let wrapper;

  const defaultProps = {
    job: mockPipelineJob,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(JobItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findJobNameComponent = () => wrapper.findComponent(JobNameComponent);
  const findJobActionButton = () => wrapper.findComponent(JobActionButton);

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('job name', () => {
      it('renders the job name component', () => {
        expect(findJobNameComponent().exists()).toBe(true);
      });

      it('sends the necessary props to the job name component', () => {
        expect(findJobNameComponent().props()).toMatchObject({
          name: mockPipelineJob.name,
          status: mockPipelineJob.detailedStatus,
        });
      });

      it('sets the correct tooltip for the job item', () => {
        const tooltip = capitalizeFirstCharacter(mockPipelineJob.detailedStatus.tooltip);

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
            jobId: mockPipelineJob.id,
            jobAction: mockPipelineJob.detailedStatus.action,
            jobName: mockPipelineJob.name,
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
