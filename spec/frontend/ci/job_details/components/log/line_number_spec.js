import { shallowMount } from '@vue/test-utils';
import LineNumber from '~/ci/job_details/components/log/line_number.vue';

describe('Job Log Line Number', () => {
  let wrapper;

  const data = {
    lineNumber: 1,
    path: '/jashkenas/underscore/-/jobs/335',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(LineNumber, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent(data);
  });

  it('renders incremented lineNunber by 1', () => {
    expect(wrapper.text()).toBe('1');
  });

  it('renders link with lineNumber as an ID', () => {
    expect(wrapper.attributes().id).toBe('L1');
  });

  it('links to the provided path with line number as anchor', () => {
    expect(wrapper.attributes().href).toBe(`${data.path}#L1`);
  });
});
