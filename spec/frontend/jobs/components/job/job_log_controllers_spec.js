import { GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import JobLogControllers from '~/jobs/components/job/job_log_controllers.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { backoffMockImplementation } from 'helpers/backoff_helper';
import * as commonUtils from '~/lib/utils/common_utils';
import { mockJobLog } from '../../mock_data';

const mockToastShow = jest.fn();

describe('Job log controllers', () => {
  let wrapper;

  beforeEach(() => {
    jest.spyOn(commonUtils, 'backOff').mockImplementation(backoffMockImplementation);
  });

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }
    commonUtils.backOff.mockReset();
  });

  const defaultProps = {
    rawPath: '/raw',
    erasePath: '/erase',
    size: 511952,
    isScrollTopDisabled: false,
    isScrollBottomDisabled: false,
    isScrollingDown: true,
    isJobLogSizeVisible: true,
    isComplete: true,
    jobLog: mockJobLog,
  };

  const createWrapper = (props, { jobLogJumpToFailures = false } = {}) => {
    wrapper = mount(JobLogControllers, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: {
          jobLogJumpToFailures,
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
  const findScrollFailure = () => wrapper.find('[data-testid="job-controller-scroll-to-failure"]');

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
          await findScrollTop().trigger('click');

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
          expect(findScrollTop().attributes('disabled')).toBeDefined();
        });

        it('does not emit scrollJobLogTop event on click', async () => {
          await findScrollTop().trigger('click');

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
          await findScrollBottom().trigger('click');

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
          await findScrollBottom().trigger('click');

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

    describe('scroll to failure button', () => {
      describe('with feature flag disabled', () => {
        it('does not display button', () => {
          createWrapper();

          expect(findScrollFailure().exists()).toBe(false);
        });
      });

      describe('with red text failures on the page', () => {
        let firstFailure;
        let secondFailure;

        beforeEach(() => {
          jest.spyOn(document, 'querySelectorAll').mockReturnValueOnce(['mock-element']);

          createWrapper({}, { jobLogJumpToFailures: true });

          firstFailure = document.createElement('div');
          firstFailure.className = 'term-fg-l-red';
          document.body.appendChild(firstFailure);

          secondFailure = document.createElement('div');
          secondFailure.className = 'term-fg-l-red';
          document.body.appendChild(secondFailure);
        });

        afterEach(() => {
          if (firstFailure) {
            firstFailure.remove();
            firstFailure = null;
          }

          if (secondFailure) {
            secondFailure.remove();
            secondFailure = null;
          }
        });

        it('is enabled', () => {
          expect(findScrollFailure().props('disabled')).toBe(false);
        });

        it('scrolls to each failure', async () => {
          jest.spyOn(firstFailure, 'scrollIntoView');

          await findScrollFailure().trigger('click');

          expect(firstFailure.scrollIntoView).toHaveBeenCalled();

          await findScrollFailure().trigger('click');

          expect(secondFailure.scrollIntoView).toHaveBeenCalled();

          await findScrollFailure().trigger('click');

          expect(firstFailure.scrollIntoView).toHaveBeenCalled();
        });
      });

      describe('with no red text failures on the page', () => {
        beforeEach(() => {
          jest.spyOn(document, 'querySelectorAll').mockReturnValueOnce([]);

          createWrapper({}, { jobLogJumpToFailures: true });
        });

        it('is disabled', () => {
          expect(findScrollFailure().props('disabled')).toBe(true);
        });
      });

      describe('when the job log is not complete', () => {
        beforeEach(() => {
          jest.spyOn(document, 'querySelectorAll').mockReturnValueOnce(['mock-element']);

          createWrapper({ isComplete: false }, { jobLogJumpToFailures: true });
        });

        it('is enabled', () => {
          expect(findScrollFailure().props('disabled')).toBe(false);
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          jest.spyOn(commonUtils, 'backOff').mockRejectedValueOnce();

          createWrapper({}, { jobLogJumpToFailures: true });
        });

        it('stays disabled', () => {
          expect(findScrollFailure().props('disabled')).toBe(true);
        });
      });
    });
  });

  describe('Job log search', () => {
    beforeEach(() => {
      createWrapper();
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
