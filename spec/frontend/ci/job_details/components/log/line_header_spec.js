import { GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import DurationBadge from '~/ci/job_details/components/log/duration_badge.vue';
import LineHeader from '~/ci/job_details/components/log/line_header.vue';
import LineNumber from '~/ci/job_details/components/log/line_number.vue';

describe('Job Log Header Line', () => {
  let wrapper;

  const defaultProps = {
    line: {
      content: [
        {
          text: 'Running with gitlab-runner 12.1.0 (de7731dd)',
          style: 'term-fg-l-green',
        },
      ],
      lineNumber: 77,
    },
    isClosed: true,
    path: '/jashkenas/underscore/-/jobs/335',
  };

  const createComponent = (props = defaultProps) => {
    wrapper = mount(LineHeader, {
      propsData: {
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);

  describe('line', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the line number component', () => {
      expect(wrapper.findComponent(LineNumber).exists()).toBe(true);
    });

    it('renders a span the provided text', () => {
      expect(wrapper.find('span').text()).toBe(defaultProps.line.content[0].text);
    });

    it('renders the provided style as a class attribute', () => {
      expect(wrapper.find('span').classes()).toContain(defaultProps.line.content[0].style);
    });
  });

  describe('when isClosed is true', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, isClosed: true });
    });

    it('sets icon name to be chevron-lg-right', () => {
      expect(findIcon().props('name')).toEqual('chevron-lg-right');
    });
  });

  describe('when isClosed is false', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, isClosed: false });
    });

    it('sets icon name to be chevron-lg-down', () => {
      expect(findIcon().props('name')).toEqual('chevron-lg-down');
    });
  });

  describe('when isClosed is not defined', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, isClosed: undefined });
    });

    it('sets icon name to be chevron-lg-right', () => {
      expect(findIcon().props('name')).toEqual('chevron-lg-down');
    });
  });

  describe('on click', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits toggleLine event', async () => {
      wrapper.trigger('click');

      await nextTick();
      expect(wrapper.emitted().toggleLine.length).toBe(1);
    });
  });

  describe('with duration', () => {
    it('renders the duration badge', () => {
      createComponent({ ...defaultProps, duration: '00:10' });
      expect(wrapper.findComponent(DurationBadge).exists()).toBe(true);
    });

    it('does not render the duration badge with hidden duration', () => {
      createComponent({ ...defaultProps, hideDuration: true, duration: '00:10' });
      expect(wrapper.findComponent(DurationBadge).exists()).toBe(false);
    });
  });

  describe('line highlighting', () => {
    describe('with hash', () => {
      beforeEach(() => {
        setWindowLocation(`http://foo.com/root/ci-project/-/jobs/6353#L77`);

        createComponent();
      });

      it('highlights line', () => {
        expect(wrapper.classes()).toContain('gl-bg-gray-700');
      });
    });

    describe('without hash', () => {
      beforeEach(() => {
        setWindowLocation(`http://foo.com/root/ci-project/-/jobs/6353`);

        createComponent();
      });

      it('does not highlight line', () => {
        expect(wrapper.classes()).not.toContain('gl-bg-gray-700');
      });
    });

    describe('search results', () => {
      it('highlights the job log lines', () => {
        createComponent({ ...defaultProps, isHighlighted: true });

        expect(wrapper.classes()).toContain('gl-bg-gray-700');
      });

      it('does not highlight the job log lines', () => {
        createComponent();

        expect(wrapper.classes()).not.toContain('gl-bg-gray-700');
      });
    });
  });
});
