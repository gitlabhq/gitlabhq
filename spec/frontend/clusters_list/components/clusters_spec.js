import { GlLoadingIcon, GlPagination, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Clusters from '~/clusters_list/components/clusters.vue';
import ClustersEmptyState from '~/clusters_list/components/clusters_empty_state.vue';
import ClusterStore from '~/clusters_list/store';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  SET_LOADING_NODES,
  SET_CLUSTERS_DATA,
  SET_LOADING_CLUSTERS,
} from '~/clusters_list/store/mutation_types';
import { apiData } from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('Clusters', () => {
  let mock;
  let store;
  let wrapper;

  const endpoint = 'some/endpoint';
  const totalClustersNumber = 6;
  const clustersEmptyStateImage = 'path/to/svg';
  const emptyStateHelpText = null;
  const addClusterPath = '/path/to/new/cluster';

  const entryData = {
    endpoint,
    imgTagsAwsText: 'AWS Icon',
    imgTagsDefaultText: 'Default Icon',
    imgTagsGcpText: 'GCP Icon',
    totalClusters: totalClustersNumber,
  };

  const provideData = {
    clustersEmptyStateImage,
    emptyStateHelpText,
    addClusterPath,
  };

  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findPaginatedButtons = () => wrapper.findComponent(GlPagination);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findStatuses = () => findTable().findAll('.js-status');
  const findEmptyState = () => wrapper.findComponent(ClustersEmptyState);

  const mockPollingApi = (response, body, header) => {
    mock.onGet(`${endpoint}?page=${header['x-page']}`).reply(response, body, header);
  };

  const createWrapper = ({ propsData = {} }) => {
    store = ClusterStore(entryData);
    wrapper = mount(Clusters, { propsData, provide: provideData, store, stubs: { GlTableLite } });
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
    mockPollingApi(HTTP_STATUS_OK, apiData, paginationHeader());

    return createWrapper({});
  });

  afterEach(() => {
    mock.restore();
  });

  describe('clusters table', () => {
    describe('when data is loading', () => {
      beforeEach(() => {
        store.commit(SET_LOADING_CLUSTERS, true);
      });

      it('displays a loader instead of the table while loading', () => {
        expect(findLoader().exists()).toBe(true);
        expect(findTable().exists()).toBe(false);
      });
    });

    describe('when clusters are present', () => {
      it('displays a table component', () => {
        expect(findTable().exists()).toBe(true);
      });
    });

    describe('when there are no clusters', () => {
      beforeEach(() => {
        store.commit(SET_CLUSTERS_DATA, {
          data: {},
          paginationInformation: {
            total: 0,
          },
        });
      });
      it('should render empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('when is loaded as a child component', () => {
      it("shouldn't render pagination buttons", () => {
        createWrapper({ limit: 6 });

        expect(findPaginatedButtons().exists()).toBe(false);
      });
    });
  });

  describe('cluster icon', () => {
    it.each`
      providerText      | lineNumber
      ${'GCP Icon'}     | ${0}
      ${'AWS Icon'}     | ${1}
      ${'Default Icon'} | ${2}
      ${'Default Icon'} | ${3}
      ${'Default Icon'} | ${4}
      ${'Default Icon'} | ${5}
    `('renders provider image and alt text for each cluster', ({ providerText, lineNumber }) => {
      const images = findTable().findAll('.js-status img');
      const image = images.at(lineNumber);

      expect(image.attributes('alt')).toBe(providerText);
    });
  });

  describe('cluster status', () => {
    it.each`
      statusName    | lineNumber | result
      ${'creating'} | ${0}       | ${true}
      ${null}       | ${1}       | ${false}
      ${null}       | ${2}       | ${false}
      ${'deleting'} | ${3}       | ${true}
      ${null}       | ${4}       | ${false}
      ${null}       | ${5}       | ${false}
    `(
      'renders $result when status=$statusName and lineNumber=$lineNumber',
      ({ lineNumber, result }) => {
        const statuses = findStatuses();
        const status = statuses.at(lineNumber);
        expect(status.findComponent(GlLoadingIcon).exists()).toBe(result);
      },
    );
  });

  describe('nodes present', () => {
    describe('nodes while loading', () => {
      it.each`
        nodeSize | lineNumber
        ${null}  | ${0}
        ${'1'}   | ${1}
        ${'2'}   | ${2}
        ${'1'}   | ${3}
        ${'1'}   | ${4}
        ${null}  | ${5}
      `('renders node size for each cluster', ({ nodeSize, lineNumber }) => {
        const sizes = findTable().findAll('td:nth-child(3)');
        const size = sizes.at(lineNumber);

        if (nodeSize) {
          expect(size.text()).toBe(nodeSize);
        } else {
          expect(size.findComponent(GlSkeletonLoader).exists()).toBe(true);
        }
      });
    });

    describe('nodes finish loading', () => {
      beforeEach(async () => {
        store.commit(SET_LOADING_NODES, false);
        await nextTick();
      });

      it.each`
        nodeText                    | lineNumber
        ${'Unable to Authenticate'} | ${0}
        ${'1'}                      | ${1}
        ${'2'}                      | ${2}
        ${'1'}                      | ${3}
        ${'1'}                      | ${4}
        ${'Unknown Error'}          | ${5}
      `('renders node size for each cluster', ({ nodeText, lineNumber }) => {
        const sizes = findTable().findAll('td:nth-child(3)');
        const size = sizes.at(lineNumber);

        expect(size.text()).toContain(nodeText);
        expect(size.findComponent(GlSkeletonLoader).exists()).toBe(false);
      });
    });

    describe('nodes with unknown quantity', () => {
      it('notifies Sentry about all missing quantity types', () => {
        expect(Sentry.captureException).toHaveBeenCalledTimes(8);
      });

      it('notifies Sentry about CPU missing quantity types', () => {
        const missingCpuTypeError = new Error('UnknownK8sCpuQuantity:1missingCpuUnit');

        expect(Sentry.captureException).toHaveBeenCalledWith(missingCpuTypeError, {
          tags: { javascript_clusters_list: 'totalCpuAndUsageError' },
        });
      });

      it('notifies Sentry about Memory missing quantity types', () => {
        const missingMemoryTypeError = new Error('UnknownK8sMemoryQuantity:1missingMemoryUnit');

        expect(Sentry.captureException).toHaveBeenCalledWith(missingMemoryTypeError, {
          tags: { javascript_clusters_list: 'totalMemoryAndUsageError' },
        });
      });
    });
  });

  describe('cluster CPU', () => {
    it.each`
      clusterCpu           | lineNumber
      ${'Loading'}         | ${0}
      ${'1.93 (87% free)'} | ${1}
      ${'3.87 (86% free)'} | ${2}
      ${'(% free)'}        | ${3}
      ${'(% free)'}        | ${4}
      ${'Loading'}         | ${5}
    `('renders total cpu for each cluster', ({ clusterCpu, lineNumber }) => {
      const clusterCpus = findTable().findAll('td:nth-child(4)');
      const cpuData = clusterCpus.at(lineNumber);

      expect(cpuData.text()).toBe(clusterCpu);
    });
  });

  describe('cluster Memory', () => {
    it.each`
      clusterMemory         | lineNumber
      ${'Loading'}          | ${0}
      ${'5.92 (78% free)'}  | ${1}
      ${'12.86 (79% free)'} | ${2}
      ${'(% free)'}         | ${3}
      ${'(% free)'}         | ${4}
      ${'Loading'}          | ${5}
    `('renders total memory for each cluster', ({ clusterMemory, lineNumber }) => {
      const clusterMemories = findTable().findAll('td:nth-child(5)');
      const memoryData = clusterMemories.at(lineNumber);

      expect(memoryData.text()).toBe(clusterMemory);
    });
  });

  describe('pagination', () => {
    const perPage = apiData.clusters.length;
    const totalFirstPage = 100;
    const totalSecondPage = 500;

    beforeEach(() => {
      mockPollingApi(HTTP_STATUS_OK, apiData, paginationHeader(totalFirstPage, perPage, 1));
      return createWrapper({});
    });

    it('should load to page 1 with header values', () => {
      const buttons = findPaginatedButtons();

      expect(buttons.props('perPage')).toBe(perPage);
      expect(buttons.props('totalItems')).toBe(totalFirstPage);
      expect(buttons.props('value')).toBe(1);
    });

    describe('when updating currentPage', () => {
      beforeEach(() => {
        mockPollingApi(HTTP_STATUS_OK, apiData, paginationHeader(totalSecondPage, perPage, 2));
        findPaginatedButtons().vm.$emit('input', 2);
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
