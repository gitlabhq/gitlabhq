import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributorsCharts from '~/contributors/components/contributors.vue';
import { createStore } from '~/contributors/stores';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

let wrapper;
let mock;
let store;
const endpoint = 'contributors/-/graphs';
const branch = 'main';
const chartData = [
  { author_name: 'John', author_email: 'jawnnypoo@gmail.com', date: '2019-05-05' },
  { author_name: 'John', author_email: 'jawnnypoo@gmail.com', date: '2019-03-03' },
];
const projectId = '23';
const commitsPath = 'some/path';

function factory() {
  mock = new MockAdapter(axios);
  jest.spyOn(axios, 'get');
  mock.onGet().reply(HTTP_STATUS_OK, chartData);
  store = createStore();

  wrapper = mountExtended(ContributorsCharts, {
    propsData: {
      endpoint,
      branch,
      projectId,
      commitsPath,
    },
    stubs: {
      GlLoadingIcon: true,
      GlAreaChart: true,
      RefSelector: true,
    },
    store,
  });
}

const findLoadingIcon = () => wrapper.findByTestId('loading-app-icon');
const findRefSelector = () => wrapper.findComponent(RefSelector);
const findHistoryButton = () => wrapper.findByTestId('history-button');
const findContributorsCharts = () => wrapper.findByTestId('contributors-charts');

describe('Contributors charts', () => {
  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    mock.restore();
  });

  it('should fetch chart data when mounted', () => {
    expect(axios.get).toHaveBeenCalledWith(endpoint);
  });

  it('should display loader whiled loading data', async () => {
    wrapper.vm.$store.state.loading = true;
    await nextTick();
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('should render charts and a RefSelector when loading completed and there is chart data', async () => {
    wrapper.vm.$store.state.loading = false;
    wrapper.vm.$store.state.chartData = chartData;
    await nextTick();

    expect(findLoadingIcon().exists()).toBe(false);
    expect(findRefSelector().exists()).toBe(true);
    expect(findRefSelector().props()).toMatchObject({
      enabledRefTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
      value: branch,
      projectId,
      translations: { dropdownHeader: 'Switch branch/tag' },
      useSymbolicRefNames: false,
      state: true,
      name: '',
    });
    expect(findContributorsCharts().exists()).toBe(true);
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should have a history button with a set href attribute', async () => {
    wrapper.vm.$store.state.loading = false;
    wrapper.vm.$store.state.chartData = chartData;
    await nextTick();

    const historyButton = findHistoryButton();
    expect(historyButton.exists()).toBe(true);
    expect(historyButton.attributes('href')).toBe(commitsPath);
  });

  it('visits a URL when clicking on a branch/tag', async () => {
    wrapper.vm.$store.state.loading = false;
    wrapper.vm.$store.state.chartData = chartData;
    await nextTick();

    findRefSelector().vm.$emit('input', branch);

    expect(visitUrl).toHaveBeenCalledWith(`${endpoint}/${branch}`);
  });
});
