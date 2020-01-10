import { mount } from '@vue/test-utils';
import LineHeader from '~/jobs/components/log/line_header.vue';
import LineNumber from '~/jobs/components/log/line_number.vue';
import DurationBadge from '~/jobs/components/log/duration_badge.vue';

describe('Job Log Header Line', () => {
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
    isClosed: true,
    path: '/jashkenas/underscore/-/jobs/335',
  };

  const createComponent = (props = {}) => {
    wrapper = mount(LineHeader, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('line', () => {
    beforeEach(() => {
      createComponent(data);
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

  describe('when isCloses is true', () => {
    beforeEach(() => {
      createComponent({ ...data, isClosed: true });
    });

    it('sets icon name to be angle-right', () => {
      expect(wrapper.vm.iconName).toEqual('angle-right');
    });
  });

  describe('when isCloses is false', () => {
    beforeEach(() => {
      createComponent({ ...data, isClosed: false });
    });

    it('sets icon name to be angle-down', () => {
      expect(wrapper.vm.iconName).toEqual('angle-down');
    });
  });

  describe('on click', () => {
    beforeEach(() => {
      createComponent(data);
    });

    it('emits toggleLine event', () => {
      wrapper.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().toggleLine.length).toBe(1);
      });
    });
  });

  describe('with duration', () => {
    beforeEach(() => {
      createComponent(Object.assign({}, data, { duration: '00:10' }));
    });

    it('renders the duration badge', () => {
      expect(wrapper.contains(DurationBadge)).toBe(true);
    });
  });
});
