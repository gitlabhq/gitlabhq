import { shallowMount } from '@vue/test-utils';
import Line from '~/jobs/components/log/line.vue';
import LineNumber from '~/jobs/components/log/line_number.vue';

describe('Job Log Line', () => {
  let wrapper;

  const data = {
    line: {
      content: [
        {
          text: 'Running with gitlab-runner 12.1.0 (de7731dd)',
          style: 'term-fg-l-green',
        },
      ],
      lineNumber: 0,
    },
    path: '/jashkenas/underscore/-/jobs/335',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(Line, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent(data);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the line number component', () => {
    expect(wrapper.contains(LineNumber)).toBe(true);
  });

  it('renders a span the provided text', () => {
    expect(wrapper.find('span').text()).toBe(data.line.content[0].text);
  });

  it('renders the provided style as a class attribute', () => {
    expect(wrapper.find('span').classes()).toContain(data.line.content[0].style);
  });
});
