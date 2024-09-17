import { GlLink, GlSearchBoxByClick } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import JobLogTopBar from '~/ci/job_details/components/job_log_top_bar.vue';
import { backoffMockImplementation } from 'helpers/backoff_helper';
import * as commonUtils from '~/lib/utils/common_utils';
import { mockJobLog } from 'jest/ci/jobs_mock_data';

const mockToastShow = jest.fn();

describe('JobLogTopBar', () => {
  let wrapper;

  beforeEach(() => {
    jest.spyOn(commonUtils, 'backOff').mockImplementation(backoffMockImplementation);
  });

  afterEach(() => {
    commonUtils.backOff.mockReset();
  });

  const defaultProps = {
    rawPath: '/raw',
    logViewerPath: '/viewer',
    size: 511952,
    isScrollTopDisabled: false,
    isScrollBottomDisabled: false,
    isScrollingDown: true,
    isJobLogSizeVisible: true,
    isComplete: true,
    jobLog: mockJobLog,
  };

  const createWrapper = (props) => {
    wrapper = mount(JobLogTopBar, {
      propsData: {
        ...defaultProps,
        ...props,
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

  const findShowingLast = () => wrapper.find('[data-testid="showing-last"]');
  const findShowingLastLinks = () => findShowingLast().findAllComponents(GlLink);
  const findRawLinkController = () => wrapper.find('[data-testid="job-raw-link-controller"]');
  const findScrollTop = () => wrapper.find('[data-testid="job-top-bar-scroll-top"]');
  const findScrollBottom = () => wrapper.find('[data-testid="job-top-bar-scroll-bottom"]');
  const findJobLogSearch = () => wrapper.findComponent(GlSearchBoxByClick);
  const findScrollFailure = () => wrapper.find('[data-testid="job-top-bar-scroll-to-failure"]');
  const findShowFullScreenButton = () =>
    wrapper.find('[data-testid="job-top-bar-enter-fullscreen"]');
  const findExitFullScreenButton = () =>
    wrapper.find('[data-testid="job-top-bar-exit-fullscreen"]');

  describe('Truncate information', () => {
    describe('with isJobLogSizeVisible', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('renders size information', () => {
        expect(findShowingLast().text()).toMatch('Showing last 499.95 KiB of log.');
      });

      it('renders links', () => {
        expect(findShowingLastLinks()).toHaveLength(2);
        expect(findShowingLastLinks().at(0).attributes('href')).toBe('/raw');
        expect(findShowingLastLinks().at(1).attributes('href')).toBe('/viewer');
      });
    });

    describe('with isJobLogSizeVisible and log viewer is not available', () => {
      beforeEach(() => {
        createWrapper({
          logViewerPath: null,
        });
      });

      it('renders size information', () => {
        expect(findShowingLastLinks()).toHaveLength(1);
        expect(findShowingLastLinks().at(0).attributes('href')).toBe('/raw');
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
      describe('with red text failures on the page', () => {
        let firstFailure;
        let secondFailure;

        beforeEach(() => {
          jest.spyOn(document, 'querySelectorAll').mockReturnValueOnce(['mock-element']);

          createWrapper();

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

          createWrapper();
        });

        it('is disabled', () => {
          expect(findScrollFailure().props('disabled')).toBe(true);
        });
      });

      describe('when the job log is not complete', () => {
        beforeEach(() => {
          jest.spyOn(document, 'querySelectorAll').mockReturnValueOnce(['mock-element']);

          createWrapper();
        });

        it('is enabled', () => {
          expect(findScrollFailure().props('disabled')).toBe(false);
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          jest.spyOn(commonUtils, 'backOff').mockRejectedValueOnce();

          createWrapper();
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
    });

    it('emits search results', () => {
      findJobLogSearch().vm.$emit('submit');

      expect(wrapper.emitted('searchResults')).toHaveLength(1);
    });

    it('clears search results', () => {
      findJobLogSearch().vm.$emit('clear');

      expect(wrapper.emitted('searchResults')).toEqual([[[]]]);
    });
  });

  describe('Fullscreen controls', () => {
    it('displays a disabled "Show fullscreen" button', () => {
      createWrapper();

      expect(findShowFullScreenButton().exists()).toBe(true);
      expect(findShowFullScreenButton().attributes('disabled')).toBe('disabled');
    });

    it('displays a enabled "Show fullscreen" button', () => {
      createWrapper({
        fullScreenModeAvailable: true,
      });

      expect(findShowFullScreenButton().exists()).toBe(true);
      expect(findShowFullScreenButton().attributes('disabled')).toBeUndefined();
    });

    it('emits a enterFullscreen event when the show fullscreen is clicked', async () => {
      createWrapper({
        fullScreenModeAvailable: true,
      });

      await findShowFullScreenButton().trigger('click');

      expect(wrapper.emitted('enterFullscreen')).toHaveLength(1);
    });

    it('displays a enabled "Exit fullscreen" button', () => {
      createWrapper({
        fullScreenModeAvailable: true,
        fullScreenEnabled: true,
      });

      expect(findExitFullScreenButton().exists()).toBe(true);
      expect(findExitFullScreenButton().attributes('disabled')).toBeUndefined();
    });

    it('emits a exitFullscreen event when the exit fullscreen is clicked', async () => {
      createWrapper({
        fullScreenModeAvailable: true,
        fullScreenEnabled: true,
      });

      await findExitFullScreenButton().trigger('click');

      expect(wrapper.emitted('exitFullscreen')).toHaveLength(1);
    });
  });
});
