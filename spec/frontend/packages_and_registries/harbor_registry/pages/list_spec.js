import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import HarborListHeader from '~/packages_and_registries/harbor_registry/components/list/harbor_list_header.vue';
import HarborRegistryList from '~/packages_and_registries/harbor_registry/pages/list.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import waitForPromises from 'helpers/wait_for_promises';
import HarborList from '~/packages_and_registries/harbor_registry/components/list/harbor_list.vue';
import CliCommands from '~/packages_and_registries/shared/components/cli_commands.vue';
import { SORT_FIELDS } from '~/packages_and_registries/harbor_registry/constants/index';
import { harborImagesResponse, defaultConfig, harborImagesList } from '../mock_data';

let mockHarborListResponse;
jest.mock('~/rest_api', () => ({
  getHarborRepositoriesList: () => mockHarborListResponse,
}));

describe('Harbor List Page', () => {
  let wrapper;

  const waitForHarborPageRequest = async () => {
    await waitForPromises();
    await nextTick();
  };

  const findHarborListHeader = () => wrapper.findComponent(HarborListHeader);
  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findHarborList = () => wrapper.findComponent(HarborList);
  const findCliCommands = () => wrapper.findComponent(CliCommands);

  const defaultHeaders = {
    'x-page': '1',
    'X-Per-Page': '20',
    'X-TOTAL': '1',
    'X-Total-Pages': '1',
  };

  const fireFirstSortUpdate = () => {
    findPersistedSearch().vm.$emit('update', { sort: 'UPDATED_DESC', filters: [] });
  };

  const mountComponent = ({ config = defaultConfig } = {}) => {
    wrapper = shallowMount(HarborRegistryList, {
      stubs: {
        HarborListHeader,
      },
      provide() {
        return {
          ...config,
        };
      },
    });
  };

  beforeEach(() => {
    mockHarborListResponse = Promise.resolve({
      data: harborImagesResponse,
      headers: defaultHeaders,
    });
  });

  it('contains harbor registry header', async () => {
    mountComponent();
    fireFirstSortUpdate();
    await waitForHarborPageRequest();
    await nextTick();

    expect(findHarborListHeader().exists()).toBe(true);
    expect(findHarborListHeader().props()).toMatchObject({
      imagesCount: 1,
      metadataLoading: false,
    });
  });

  describe('isLoading is true', () => {
    it('shows the skeleton loader', () => {
      mountComponent();
      fireFirstSortUpdate();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('harborList is not visible', () => {
      mountComponent();

      expect(findHarborList().exists()).toBe(false);
    });

    it('cli commands is not visible', () => {
      mountComponent();

      expect(findCliCommands().exists()).toBe(false);
    });

    it('title has the metadataLoading props set to true', () => {
      mountComponent();
      fireFirstSortUpdate();

      expect(findHarborListHeader().props('metadataLoading')).toBe(true);
    });
  });

  describe('list is not empty', () => {
    describe('unfiltered state', () => {
      it('quick start is visible', async () => {
        mountComponent();
        fireFirstSortUpdate();

        await waitForHarborPageRequest();
        await nextTick();

        expect(findCliCommands().exists()).toBe(true);
      });

      it('list component is visible', async () => {
        mountComponent();
        fireFirstSortUpdate();

        await waitForHarborPageRequest();
        await nextTick();

        expect(findHarborList().exists()).toBe(true);
        expect(findHarborList().props()).toMatchObject({
          images: harborImagesList,
          metadataLoading: false,
          pageInfo: {
            page: 1,
            perPage: 20,
            total: 1,
            totalPages: 1,
          },
        });
      });
    });

    describe('search and sorting', () => {
      it('has a persisted search box element', async () => {
        mountComponent();
        fireFirstSortUpdate();
        await waitForHarborPageRequest();
        await nextTick();

        const harborRegistrySearch = findPersistedSearch();
        expect(harborRegistrySearch.exists()).toBe(true);
        expect(harborRegistrySearch.props()).toMatchObject({
          defaultOrder: 'UPDATED',
          defaultSort: 'desc',
          sortableFields: SORT_FIELDS,
        });
      });
    });
  });
});
