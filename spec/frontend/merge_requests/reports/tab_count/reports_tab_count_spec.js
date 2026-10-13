import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import ReportsTabCount from '~/merge_requests/reports/tab_count/reports_tab_count.vue';
import SmartInterval from '~/smart_interval';
import { observable } from '~/lib/utils/observable';
import { resetMergeRequestData } from '~/merge_requests/reports/merge_request_data';

jest.mock('ee_else_ce/vue_merge_request_widget/services/mr_widget_service', () => ({
  fetchInitialData: jest.fn(),
}));

jest.mock('~/smart_interval');

const tabData = observable('mr_page_tab_data', { tabs: [] });

const COMPLETE = { active: false, iid: 1, details: { status: {} } };

describe('ReportsTabCount', () => {
  let wrapper;

  const mockData = (data) =>
    MRWidgetService.fetchInitialData.mockResolvedValue({ data: { current_user: {}, ...data } });

  const createComponent = async () => {
    wrapper = shallowMount(ReportsTabCount);

    await waitForPromises();
  };

  beforeEach(() => {
    window.gl = {
      mrWidgetData: {
        merge_request_cached_widget_path: '/cached',
        merge_request_widget_path: '/widget',
      },
    };
    tabData.tabs = [['reports', 'Reports', '/reports', '-']];
  });

  afterEach(() => {
    resetMergeRequestData();
    delete window.gl;
  });

  it.each`
    description        | reports                                                                                                                            | expected
    ${'no reports'}    | ${{}}                                                                                                                              | ${'0'}
    ${'code quality'}  | ${{ codequality_reports_path: '/cq' }}                                                                                             | ${'1'}
    ${'accessibility'} | ${{ accessibility_report_path: '/a11y' }}                                                                                          | ${'1'}
    ${'test summary'}  | ${{ test_reports_path: '/t' }}                                                                                                     | ${'1'}
    ${'terraform'}     | ${{ terraform_reports_path: '/tf' }}                                                                                               | ${'1'}
    ${'every report'}  | ${{ codequality_reports_path: '/cq', accessibility_report_path: '/a11y', test_reports_path: '/t', terraform_reports_path: '/tf' }} | ${'4'}
  `('renders $expected for $description', async ({ reports, expected }) => {
    mockData({ pipeline: COMPLETE, ...reports });

    await createComponent();

    expect(wrapper.text()).toBe(expected);
    expect(tabData.tabs[0][3]).toBe(expected);
  });

  it.each`
    description                 | mockRequest
    ${'nothing has loaded yet'} | ${() => MRWidgetService.fetchInitialData.mockReturnValue(new Promise(() => {}))}
    ${'there is no pipeline'}   | ${() => mockData({ codequality_reports_path: '/cq' })}
    ${'the pipeline is active'} | ${() => mockData({ pipeline: { ...COMPLETE, active: true } })}
    ${'the fetch failed'}       | ${() => MRWidgetService.fetchInitialData.mockRejectedValue(new Error())}
  `('leaves the placeholder alone when $description', async ({ mockRequest }) => {
    mockRequest();

    await createComponent();

    expect(wrapper.text()).toBe('-');
    expect(tabData.tabs[0][3]).toBe('-');
  });

  it('updates the sticky header when the tab data arrives after the count', async () => {
    tabData.tabs = [];
    mockData({ pipeline: COMPLETE, codequality_reports_path: '/cq' });

    await createComponent();

    tabData.tabs = [['reports', 'Reports', '/reports', '-']];
    await nextTick();

    expect(tabData.tabs[0][3]).toBe('1');
  });

  it('runs a single poller no matter how many consumers mount', async () => {
    mockData({ pipeline: { ...COMPLETE, active: true } });

    await createComponent();
    shallowMount(ReportsTabCount);
    await waitForPromises();

    expect(SmartInterval).toHaveBeenCalledTimes(1);
  });
});
