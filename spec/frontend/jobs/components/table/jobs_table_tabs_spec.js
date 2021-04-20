import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';

describe('Jobs Table Tabs', () => {
  let wrapper;

  const defaultProps = {
    jobCounts: { all: 848, pending: 0, running: 0, finished: 704 },
  };

  const findTab = (testId) => wrapper.findByTestId(testId);

  const createComponent = () => {
    wrapper = extendedWrapper(
      mount(JobsTableTabs, {
        provide: {
          ...defaultProps,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    tabId                  | text          | count
    ${'jobs-all-tab'}      | ${'All'}      | ${defaultProps.jobCounts.all}
    ${'jobs-pending-tab'}  | ${'Pending'}  | ${defaultProps.jobCounts.pending}
    ${'jobs-running-tab'}  | ${'Running'}  | ${defaultProps.jobCounts.running}
    ${'jobs-finished-tab'} | ${'Finished'} | ${defaultProps.jobCounts.finished}
  `('displays the right tab text and badge count', ({ tabId, text, count }) => {
    expect(trimText(findTab(tabId).text())).toBe(`${text} ${count}`);
  });
});
