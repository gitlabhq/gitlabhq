import { mount } from '@vue/test-utils';
import JobLogControllers from '~/jobs/components/job_log_controllers.vue';

describe('Job log controllers', () => {
  let wrapper;

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const defaultProps = {
    rawPath: '/raw',
    erasePath: '/erase',
    size: 511952,
    isScrollTopDisabled: false,
    isScrollBottomDisabled: false,
    isScrollingDown: true,
    isTraceSizeVisible: true,
  };

  const createWrapper = props => {
    wrapper = mount(JobLogControllers, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findTruncatedInfo = () => wrapper.find('[data-testid="log-truncated-info"]');
  const findRawLink = () => wrapper.find('[data-testid="raw-link"]');
  const findRawLinkController = () => wrapper.find('[data-testid="job-raw-link-controller"]');
  const findEraseLink = () => wrapper.find('[data-testid="job-log-erase-link"]');
  const findScrollTop = () => wrapper.find('[data-testid="job-controller-scroll-top"]');
  const findScrollBottom = () => wrapper.find('[data-testid="job-controller-scroll-bottom"]');

  describe('Truncate information', () => {
    describe('with isTraceSizeVisible', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders size information', () => {
        expect(findTruncatedInfo().text()).toMatch('499.95 KiB');
      });

      it('renders link to raw trace', () => {
        expect(findRawLink().attributes('href')).toBe(defaultProps.rawPath);
      });
    });
  });

  describe('links section', () => {
    describe('with raw trace path', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders raw trace link', () => {
        expect(findRawLinkController().attributes('href')).toBe(defaultProps.rawPath);
      });
    });

    describe('without raw trace path', () => {
      beforeEach(() => {
        createWrapper({
          rawPath: null,
        });
      });

      it('does not render raw trace link', () => {
        expect(findRawLinkController().exists()).toBe(false);
      });
    });

    describe('when is erasable', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders erase job link', () => {
        expect(findEraseLink().exists()).toBe(true);
      });
    });

    describe('when it is not erasable', () => {
      beforeEach(() => {
        createWrapper({
          erasePath: null,
        });
      });

      it('does not render erase button', () => {
        expect(findEraseLink().exists()).toBe(false);
      });
    });
  });

  describe('scroll buttons', () => {
    describe('scroll top button', () => {
      describe('when user can scroll top', () => {
        beforeEach(() => {
          createWrapper({
            isScrollTopDisabled: false,
          });
        });

        it('emits scrollJobLogTop event on click', async () => {
          findScrollTop().trigger('click');

          await wrapper.vm.$nextTick();

          expect(wrapper.emitted().scrollJobLogTop).toHaveLength(1);
        });
      });

      describe('when user can not scroll top', () => {
        beforeEach(() => {
          createWrapper({
            isScrollTopDisabled: true,
            isScrollBottomDisabled: false,
            isScrollingDown: false,
          });
        });

        it('renders disabled scroll top button', () => {
          expect(findScrollTop().attributes('disabled')).toBe('disabled');
        });

        it('does not emit scrollJobLogTop event on click', async () => {
          findScrollTop().trigger('click');

          await wrapper.vm.$nextTick();

          expect(wrapper.emitted().scrollJobLogTop).toBeUndefined();
        });
      });
    });

    describe('scroll bottom button', () => {
      describe('when user can scroll bottom', () => {
        beforeEach(() => {
          createWrapper();
        });

        it('emits scrollJobLogBottom event on click', async () => {
          findScrollBottom().trigger('click');

          await wrapper.vm.$nextTick();

          expect(wrapper.emitted().scrollJobLogBottom).toHaveLength(1);
        });
      });

      describe('when user can not scroll bottom', () => {
        beforeEach(() => {
          createWrapper({
            isScrollTopDisabled: false,
            isScrollBottomDisabled: true,
            isScrollingDown: false,
          });
        });

        it('renders disabled scroll bottom button', () => {
          expect(findScrollBottom().attributes('disabled')).toEqual('disabled');
        });

        it('does not emit scrollJobLogBottom event on click', async () => {
          findScrollBottom().trigger('click');

          await wrapper.vm.$nextTick();

          expect(wrapper.emitted().scrollJobLogBottom).toBeUndefined();
        });
      });

      describe('while isScrollingDown is true', () => {
        beforeEach(() => {
          createWrapper();
        });

        it('renders animate class for the scroll down button', () => {
          expect(findScrollBottom().classes()).toContain('animate');
        });
      });

      describe('while isScrollingDown is false', () => {
        beforeEach(() => {
          createWrapper({
            isScrollTopDisabled: true,
            isScrollBottomDisabled: false,
            isScrollingDown: false,
          });
        });

        it('does not render animate class for the scroll down button', () => {
          expect(findScrollBottom().classes()).not.toContain('animate');
        });
      });
    });
  });
});
