import { shallowMount } from '@vue/test-utils';
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

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

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
      expect(findJobNameComponent().attributes('title')).toBe(
        mockPipelineJob.detailedStatus.tooltip,
      );
    });
  });
});
