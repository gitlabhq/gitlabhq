import { GlAlert, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import CodeCoverage from '~/pages/projects/graphs/components/code_coverage.vue';
import { codeCoverageMockData, sortedDataByDates } from './mock_data';

describe('Code Coverage', () => {
  let wrapper;
  let mockAxios;

  const graphEndpoint = '/graph';
  const graphStartDate = '13 February';
  const graphEndDate = '12 May';
  const graphRef = 'master';
  const graphCsvPath = 'url/';

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListBoxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findFirstListBoxItem = () => findListBoxItems().at(0);
  const findSecondListBoxItem = () => findListBoxItems().at(1);
  const findDownloadButton = () => wrapper.find('[data-testid="download-button"]');

  const createComponent = () => {
    wrapper = shallowMount(CodeCoverage, {
      propsData: {
        graphEndpoint,
        graphStartDate,
        graphEndDate,
        graphRef,
        graphCsvPath,
      },
      stubs: { GlCollapsibleListbox },
    });
  };

  describe('when fetching data is successful', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, codeCoverageMockData);

      createComponent();

      return waitForPromises();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('renders the area chart', () => {
      expect(findAreaChart().exists()).toBe(true);
    });

    it('sorts the dates in ascending order', () => {
      expect(wrapper.vm.sortedData).toEqual(sortedDataByDates);
    });

    it('shows no error messages', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not render download button', () => {
      expect(findDownloadButton().exists()).toBe(true);
    });
  });

  describe('when fetching data fails', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(HTTP_STATUS_BAD_REQUEST);

      createComponent();

      return waitForPromises();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('renders an error message', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes().variant).toBe('danger');
    });

    it('still renders an empty graph', () => {
      expect(findAreaChart().exists()).toBe(true);
    });
  });

  describe('when fetching data succeed but returns an empty state', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, []);

      createComponent();

      return waitForPromises();
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('renders an information message', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().attributes().variant).toBe('info');
    });

    it('still renders an empty graph', () => {
      expect(findAreaChart().exists()).toBe(true);
    });

    it('does not render download button', () => {
      expect(findDownloadButton().exists()).toBe(false);
    });
  });

  describe('dropdown options', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, codeCoverageMockData);

      createComponent();

      return waitForPromises();
    });

    it('renders the dropdown with all custom names as options', () => {
      expect(findListBox().exists()).toBe(true);
      expect(findListBoxItems()).toHaveLength(codeCoverageMockData.length);
      expect(findFirstListBoxItem().text()).toBe(codeCoverageMockData[0].group_name);
    });
  });

  describe('interactions', () => {
    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
      mockAxios.onGet().replyOnce(HTTP_STATUS_OK, codeCoverageMockData);

      createComponent();

      return waitForPromises();
    });

    it('updates the selected dropdown option with an icon', async () => {
      findListBox().vm.$emit('select', '1');

      await nextTick();

      expect(findFirstListBoxItem().attributes('isselected')).toBeUndefined();
      expect(findSecondListBoxItem().attributes('isselected')).toBe('true');
    });

    it('updates the graph data when selecting a different option in dropdown', async () => {
      const originalSelectedData = wrapper.vm.selectedDailyCoverage;
      const expectedData = codeCoverageMockData[1];

      findListBox().vm.$emit('select', '1');

      await nextTick();

      expect(wrapper.vm.selectedDailyCoverage).not.toStrictEqual(originalSelectedData);
      expect(wrapper.vm.selectedDailyCoverage).toStrictEqual(expectedData);
    });
  });
});
