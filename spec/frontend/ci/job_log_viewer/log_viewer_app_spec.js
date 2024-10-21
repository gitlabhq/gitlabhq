import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { scrollToElement } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import { stubPerformanceWebAPI } from 'helpers/performance';

import LogViewerApp from '~/ci/job_log_viewer/log_viewer_app.vue';

import LogViewerTopBar from '~/ci/job_log_viewer/components/log_viewer_top_bar.vue';
import LogViewer from '~/ci/job_log_viewer/components/log_viewer.vue';
import { fetchLogLines } from '~/ci/job_log_viewer/lib/generate_stream';

jest.mock('~/alert');
jest.mock('~/ci/job_log_viewer/lib/generate_stream');
jest.mock('~/lib/utils/common_utils');

const mockLog = [{ content: [{ text: 'line' }], sections: [] }];
const mockLogWithTimestamp = [
  { content: [{ text: 'line' }], sections: [], timestamp: '2024-10-16T20:27:04.773359Z' },
];

describe('LogViewerApp', () => {
  let wrapper;

  const createWrapper = ({ mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(LogViewerApp, {
      propsData: {
        rawLogPath: '/job/1/raw',
      },
      ...options,
    });
  };

  const findLogViewerTopBar = () => wrapper.findComponent(LogViewerTopBar);
  const findLogViewer = () => wrapper.findComponent(LogViewer);
  const findUtcHint = () => wrapper.findByTestId('utc-hint');

  beforeEach(() => {
    stubPerformanceWebAPI();

    fetchLogLines.mockResolvedValue(mockLog);
  });

  it('renders help popover', () => {
    createWrapper();

    expect(findLogViewerTopBar().exists()).toBe(true);
  });

  it('renders a log', async () => {
    createWrapper();

    await waitForPromises();

    expect(findLogViewer().props()).toEqual({ loading: false, log: mockLog });
  });

  it('renders a loading log', async () => {
    fetchLogLines.mockReturnValue(new Promise(() => {}));
    createWrapper();

    await waitForPromises();

    expect(findLogViewer().props()).toEqual({ loading: true, log: [] });
  });

  it('navigates to bookmarked line', async () => {
    setWindowLocation('#L1');

    createWrapper({
      mountFn: mountExtended,
      attachTo: document.body,
    });

    await waitForPromises();

    expect(scrollToElement).toHaveBeenCalledWith(wrapper.find('#L1').element);
  });

  it('shows alert when log cannot be fetched', async () => {
    const error = new Error('Something went wrong');
    fetchLogLines.mockRejectedValue(error);

    createWrapper();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while loading the log.',
      captureError: true,
      error,
    });
    expect(findLogViewer().props()).toEqual({ loading: false, log: [] });
  });

  describe('UTC hint', () => {
    it.each`
      log                     | condition                         | expectation       | expectedValue
      ${mockLogWithTimestamp} | ${'log has timestamps'}           | ${'is shown'}     | ${true}
      ${mockLog}              | ${'log does not have timestamps'} | ${'is not shown'} | ${false}
    `('$expectation when $condition', async ({ log, expectedValue }) => {
      fetchLogLines.mockResolvedValue(log);

      createWrapper({
        mountFn: mountExtended,
        attachTo: document.body,
      });

      await waitForPromises();

      expect(findUtcHint().exists()).toBe(expectedValue);
    });
  });
});
