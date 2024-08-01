import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFilteredSearchToken } from '@gitlab/ui';
import HarborDetailsPage from '~/packages_and_registries/harbor_registry/pages/details.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import ArtifactsList from '~/packages_and_registries/harbor_registry/components/details/artifacts_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import DetailsHeader from '~/packages_and_registries/harbor_registry/components/details/details_header.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  NAME_SORT_FIELD,
  TOKEN_TYPE_TAG_NAME,
} from '~/packages_and_registries/harbor_registry/constants/index';
import { harborArtifactsResponse, harborArtifactsList, defaultConfig } from '../mock_data';

let mockHarborArtifactsResponse;

jest.mock('~/rest_api', () => ({
  getHarborArtifacts: () => mockHarborArtifactsResponse,
}));

describe('Harbor Details Page', () => {
  let wrapper;

  const findTagsLoader = () => wrapper.findComponent(TagsLoader);
  const findArtifactsList = () => wrapper.findComponent(ArtifactsList);
  const findDetailsHeader = () => wrapper.findComponent(DetailsHeader);
  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);

  const waitForHarborDetailRequest = async () => {
    await waitForPromises();
    await nextTick();
  };

  const $route = {
    params: {
      project: 'test-project',
      image: 'test-repository',
    },
  };

  const breadCrumbState = {
    updateName: jest.fn(),
    updateHref: jest.fn(),
  };

  const defaultHeaders = {
    'x-page': '1',
    'X-Per-Page': '20',
    'X-TOTAL': '1',
    'X-Total-Pages': '1',
  };

  const mountComponent = ({ config = defaultConfig } = {}) => {
    wrapper = shallowMount(HarborDetailsPage, {
      mocks: {
        $route,
      },
      provide() {
        return {
          breadCrumbState,
          ...config,
        };
      },
    });
  };

  beforeEach(() => {
    mockHarborArtifactsResponse = Promise.resolve({
      data: harborArtifactsResponse,
      headers: defaultHeaders,
    });
  });

  describe('when isLoading is true', () => {
    it('shows the loader', () => {
      mountComponent();

      expect(findTagsLoader().exists()).toBe(true);
    });

    it('does not show the list', () => {
      mountComponent();

      expect(findArtifactsList().exists()).toBe(false);
    });
  });

  describe('artifacts list', () => {
    it('exists', async () => {
      mountComponent();

      findPersistedSearch().vm.$emit('update', { sort: 'NAME_ASC', filters: [] });
      await waitForHarborDetailRequest();

      expect(findArtifactsList().exists()).toBe(true);
    });

    it('has the correct props bound', async () => {
      mountComponent();

      findPersistedSearch().vm.$emit('update', { sort: 'NAME_ASC', filters: [] });
      await waitForHarborDetailRequest();

      expect(findArtifactsList().props()).toMatchObject({
        isLoading: false,
        filter: '',
        artifacts: harborArtifactsList,
        pageInfo: {
          page: 1,
          perPage: 20,
          total: 1,
          totalPages: 1,
        },
      });
    });
  });

  describe('persisted search', () => {
    it('has the correct props', () => {
      mountComponent();

      expect(findPersistedSearch().props()).toMatchObject({
        sortableFields: [NAME_SORT_FIELD],
        defaultOrder: NAME_SORT_FIELD.orderBy,
        defaultSort: 'asc',
        tokens: [
          {
            type: TOKEN_TYPE_TAG_NAME,
            icon: 'tag',
            title: 'Tag',
            unique: true,
            token: GlFilteredSearchToken,
            operators: OPERATORS_IS,
          },
        ],
      });
    });
  });

  describe('header', () => {
    it('has the correct props', async () => {
      mountComponent();

      findPersistedSearch().vm.$emit('update', { sort: 'NAME_ASC', filters: [] });
      await waitForHarborDetailRequest();

      expect(findDetailsHeader().props()).toMatchObject({
        imagesDetail: {
          name: 'test-project/test-repository',
          artifactCount: 1,
        },
      });
    });
  });
});
