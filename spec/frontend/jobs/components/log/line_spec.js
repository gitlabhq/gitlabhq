import { shallowMount } from '@vue/test-utils';
import Line from '~/jobs/components/log/line.vue';
import LineNumber from '~/jobs/components/log/line_number.vue';

const httpUrl = 'http://example.com';
const httpsUrl = 'https://example.com';

const mockProps = ({ text = 'Running with gitlab-runner 12.1.0 (de7731dd)' } = {}) => ({
  line: {
    content: [
      {
        text,
        style: 'term-fg-l-green',
      },
    ],
    lineNumber: 0,
  },
  path: '/jashkenas/underscore/-/jobs/335',
});

describe('Job Log Line', () => {
  let wrapper;
  let data;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(Line, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    data = mockProps();
    createComponent(data);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the line number component', () => {
    expect(wrapper.find(LineNumber).exists()).toBe(true);
  });

  it('renders a span the provided text', () => {
    expect(wrapper.find('span').text()).toBe(data.line.content[0].text);
  });

  it('renders the provided style as a class attribute', () => {
    expect(wrapper.find('span').classes()).toContain(data.line.content[0].style);
  });

  describe('when the line contains a link', () => {
    const findLink = () => wrapper.find('span a');

    it('renders an http link', () => {
      createComponent(mockProps({ text: httpUrl }));

      expect(findLink().text()).toBe(httpUrl);
      expect(findLink().attributes().href).toEqual(httpUrl);
    });

    it('renders an https link', () => {
      createComponent(mockProps({ text: httpsUrl }));

      expect(findLink().text()).toBe(httpsUrl);
      expect(findLink().attributes().href).toEqual(httpsUrl);
    });

    it('renders a link with rel nofollow and noopener', () => {
      createComponent(mockProps({ text: httpsUrl }));

      expect(findLink().attributes().rel).toBe('nofollow noopener');
    });

    test.each`
      type           | text
      ${'ftp'}       | ${'ftp://example.com/file'}
      ${'email'}     | ${'email@example.com'}
      ${'no scheme'} | ${'example.com/page'}
    `('does not render a $type link', ({ text }) => {
      createComponent(mockProps({ text }));
      expect(findLink().exists()).toBe(false);
    });
  });
});
