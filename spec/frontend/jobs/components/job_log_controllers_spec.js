import { GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import JobLogControllers from '~/jobs/components/job_log_controllers.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { mockJobLog } from '../mock_data';

const mockToastShow = jest.fn();

describe('Job log controllers', () => {
  let wrapper;

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }
  });

  const defaultProps = {
    rawPath: '/raw',
    erasePath: '/erase',
    size: 511952,
    isScrollTopDisabled: false,
    isScrollBottomDisabled: false,
    isScrollingDown: true,
    isJobLogSizeVisible: true,
    jobLog: mockJobLog,
  };

  const createWrapper = (props, jobLogSearch = false) => {
    wrapper = mount(JobLogControllers, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: {
          jobLogSearch,
        },
      },
      data() {
        return {
          searchTerm: '82',
        };
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findTruncatedInfo = () => wrapper.find('[data-testid="log-truncated-info"]');
  const findRawLink = () => wrapper.find('[data-testid="raw-link"]');
  const findRawLinkController = () => wrapper.find('[data-testid="job-raw-link-controller"]');
  const findScrollTop = () => wrapper.find('[data-testid="job-controller-scroll-top"]');
  const findScrollBottom = () => wrapper.find('[data-testid="job-controller-scroll-bottom"]');
  const findJobLogSearch = () => wrapper.findComponent(GlSearchBoxByClick);
  const findSearchHelp = () => wrapper.findComponent(HelpPopover);

  describe('Truncate information', () => {
    describe('with isJobLogSizeVisible', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders size information', () => {
        expect(findTruncatedInfo().text()).toMatch('499.95 KiB');
      });

      it('renders link to raw job log', () => {
        expect(findRawLink().attributes('href')).toBe(defaultProps.rawPath);
      });
    });
  });

  describe('links section', () => {
    describe('with raw job log path', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders raw job log link', () => {
        expect(findRawLinkController().attributes('href')).toBe(defaultProps.rawPath);
      });
    });

    describe('without raw job log path', () => {
      beforeEach(() => {
        createWrapper({
          rawPath: null,
        });
      });

      it('does not render raw job log link', () => {
        expect(findRawLinkController().exists()).toBe(false);
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

          await nextTick();

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

          await nextTick();

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

          await nextTick();

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

          await nextTick();

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

  describe('Job log search', () => {
    describe('with feature flag off', () => {
      it('does not display job log search', () => {
        createWrapper();

        expect(findJobLogSearch().exists()).toBe(false);
        expect(findSearchHelp().exists()).toBe(false);
      });
    });

    describe('with feature flag on', () => {
      beforeEach(() => {
        createWrapper({}, { jobLogSearch: true });
      });

      it('displays job log search', () => {
        expect(findJobLogSearch().exists()).toBe(true);
        expect(findSearchHelp().exists()).toBe(true);
      });

      it('emits search results', () => {
        const expectedSearchResults = [[[mockJobLog[6].lines[1], mockJobLog[6].lines[2]]]];

        findJobLogSearch().vm.$emit('submit');

        expect(wrapper.emitted('searchResults')).toEqual(expectedSearchResults);
      });

      it('clears search results', () => {
        findJobLogSearch().vm.$emit('clear');

        expect(wrapper.emitted('searchResults')).toEqual([[[]]]);
      });
    });
  });
});
