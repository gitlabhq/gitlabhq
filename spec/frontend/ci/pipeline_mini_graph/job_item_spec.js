import { shallowMount } from '@vue/test-utils';
import JobItem from '~/ci/pipeline_mini_graph/job_item.vue';

describe('JobItem', () => {
  let wrapper;

  const defaultProps = {
    job: { id: '3' },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(JobItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the received HTML', () => {
      expect(wrapper.html()).toContain(defaultProps.job.id);
    });
  });
});
