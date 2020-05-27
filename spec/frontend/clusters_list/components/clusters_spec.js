import axios from '~/lib/utils/axios_utils';
import Clusters from '~/clusters_list/components/clusters.vue';
import ClusterStore from '~/clusters_list/store';
import MockAdapter from 'axios-mock-adapter';
import { apiData } from '../mock_data';
import { mount } from '@vue/test-utils';
import { GlLoadingIcon, GlTable, GlPagination } from '@gitlab/ui';

describe('Clusters', () => {
  let mock;
  let store;
  let wrapper;

  const endpoint = 'some/endpoint';

  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findPaginatedButtons = () => wrapper.find(GlPagination);
  const findTable = () => wrapper.find(GlTable);
  const findStatuses = () => findTable().findAll('.js-status');

  const mockPollingApi = (response, body, header) => {
    mock.onGet(`${endpoint}?page=${header['x-page']}`).reply(response, body, header);
  };

  const mountWrapper = () => {
    store = ClusterStore({ endpoint });
    wrapper = mount(Clusters, { store });
    return axios.waitForAll();
  };

  const paginationHeader = (total = apiData.clusters.length, perPage = 20, currentPage = 1) => {
    return {
      'x-total': total,
      'x-per-page': perPage,
      'x-page': currentPage,
    };
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockPollingApi(200, apiData, paginationHeader());

    return mountWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('clusters table', () => {
    describe('when data is loading', () => {
      beforeEach(() => {
        wrapper.vm.$store.state.loading = true;
        return wrapper.vm.$nextTick();
      });

      it('displays a loader instead of the table while loading', () => {
        expect(findLoader().exists()).toBe(true);
        expect(findTable().exists()).toBe(false);
      });
    });

    it('displays a table component', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders the correct table headers', () => {
      const tableHeaders = wrapper.vm.fields;
      const headers = findTable().findAll('th');

      expect(headers.length).toBe(tableHeaders.length);

      tableHeaders.forEach((headerText, i) =>
        expect(headers.at(i).text()).toEqual(headerText.label),
      );
    });

    it('should stack on smaller devices', () => {
      expect(findTable().classes()).toContain('b-table-stacked-md');
    });
  });

  describe('cluster status', () => {
    it.each`
      statusName                  | className       | lineNumber
      ${'disabled'}               | ${'disabled'}   | ${0}
      ${'unreachable'}            | ${'bg-danger'}  | ${1}
      ${'authentication_failure'} | ${'bg-warning'} | ${2}
      ${'deleting'}               | ${null}         | ${3}
      ${'created'}                | ${'bg-success'} | ${4}
      ${'default'}                | ${'bg-white'}   | ${5}
    `('renders a status for each cluster', ({ statusName, className, lineNumber }) => {
      const statuses = findStatuses();
      const status = statuses.at(lineNumber);
      if (statusName !== 'deleting') {
        const statusIndicator = status.find('.cluster-status-indicator');
        expect(statusIndicator.exists()).toBe(true);
        expect(statusIndicator.classes()).toContain(className);
      } else {
        expect(status.find(GlLoadingIcon).exists()).toBe(true);
      }
    });
  });

  describe('nodes present', () => {
    it.each`
      nodeSize     | lineNumber
      ${'Unknown'} | ${0}
      ${'1'}       | ${1}
      ${'2'}       | ${2}
      ${'Unknown'} | ${3}
      ${'Unknown'} | ${4}
      ${'Unknown'} | ${5}
    `('renders node size for each cluster', ({ nodeSize, lineNumber }) => {
      const sizes = findTable().findAll('td:nth-child(3)');
      const size = sizes.at(lineNumber);

      expect(size.text()).toBe(nodeSize);
    });
  });

  describe('pagination', () => {
    const perPage = apiData.clusters.length;
    const totalFirstPage = 100;
    const totalSecondPage = 500;

    beforeEach(() => {
      mockPollingApi(200, apiData, paginationHeader(totalFirstPage, perPage, 1));
      return mountWrapper();
    });

    it('should load to page 1 with header values', () => {
      const buttons = findPaginatedButtons();

      expect(buttons.props('perPage')).toBe(perPage);
      expect(buttons.props('totalItems')).toBe(totalFirstPage);
      expect(buttons.props('value')).toBe(1);
    });

    describe('when updating currentPage', () => {
      beforeEach(() => {
        mockPollingApi(200, apiData, paginationHeader(totalSecondPage, perPage, 2));
        wrapper.setData({ currentPage: 2 });
        return axios.waitForAll();
      });

      it('should change pagination when currentPage changes', () => {
        const buttons = findPaginatedButtons();

        expect(buttons.props('perPage')).toBe(perPage);
        expect(buttons.props('totalItems')).toBe(totalSecondPage);
        expect(buttons.props('value')).toBe(2);
      });
    });
  });
});
