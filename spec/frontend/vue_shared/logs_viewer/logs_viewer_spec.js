import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import LogsViewer from '~/vue_shared/components/logs_viewer/logs_viewer.vue';
import LogLine from '~/vue_shared/components/logs_viewer/log_line.vue';
import LogsTopBar from '~/vue_shared/components/logs_viewer/logs_top_bar.vue';

describe('logs_viewer.vue', () => {
  let wrapper;

  const logLines = [
    {
      content: [{ text: 'line 1' }],
      lineNumber: 1,
      lineId: 'L1',
    },
    {
      content: [{ text: 'line 2' }],
      lineNumber: 2,
      lineId: 'L2',
    },
  ];

  const defaultProps = {
    logLines,
    highlightedLine: 'L2',
  };

  const defaultSlots = {
    'header-details': '<b>slot value</b>',
  };

  const createWrapper = (props = {}) => {
    const propsData = { ...defaultProps, ...props };

    wrapper = shallowMount(LogsViewer, {
      propsData,
      slots: defaultSlots,
    });
  };

  const findTopBar = () => wrapper.findComponent(LogsTopBar);
  const findLogLines = () => wrapper.findAllComponents(LogLine);

  describe('when rendered', () => {
    describe('in default state', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('should render the top bar', () => {
        const topBar = findTopBar();

        expect(topBar.props()).toMatchObject({
          isFullScreen: false,
          isFollowing: true,
        });
      });

      it('should provide custom slot to the top bar', () => {
        expect(findTopBar().text()).toBe('slot value');
      });

      it('should render log lines', () => {
        const lines = findLogLines();

        expect(lines).toHaveLength(2);
        expect(lines.at(0).attributes('ishighlighted')).toBe(undefined);
        expect(lines.at(1).attributes('ishighlighted')).toBe('true');
      });

      describe('when scroll to bottom is clicked the first time', () => {
        let topBar;
        beforeEach(async () => {
          topBar = findTopBar();
          topBar.vm.$emit('scrollToBottom');
          await waitForPromises();
        });

        it('should stop following bottom line', () => {
          expect(topBar.props().isFollowing).toBe(false);
        });

        describe('when scroll to bottom is clicked the second time', () => {
          beforeEach(async () => {
            topBar.vm.$emit('scrollToBottom');
            await waitForPromises();
          });

          it('should start following bottom line', () => {
            expect(topBar.props().isFollowing).toBe(true);
          });
        });
      });
    });
  });
});
