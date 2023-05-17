import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import HarborTagsPage from '~/packages_and_registries/harbor_registry/pages/harbor_tags.vue';
import TagsHeader from '~/packages_and_registries/harbor_registry/components/tags/tags_header.vue';
import TagsList from '~/packages_and_registries/harbor_registry/components/tags/tags_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { defaultConfig, harborTagsResponse, mockArtifactDetail } from '../mock_data';

let mockHarborTagsResponse;

jest.mock('~/rest_api', () => ({
  getHarborTags: () => mockHarborTagsResponse,
}));

describe('Harbor Tags page', () => {
  let wrapper;

  const findTagsHeader = () => wrapper.findComponent(TagsHeader);
  const findTagsList = () => wrapper.findComponent(TagsList);

  const waitForHarborTagsRequest = async () => {
    await waitForPromises();
    await nextTick();
  };

  const breadCrumbState = {
    updateName: jest.fn(),
    updateHref: jest.fn(),
  };

  const $route = {
    params: mockArtifactDetail,
  };

  const defaultHeaders = {
    'x-page': '1',
    'X-Per-Page': '20',
    'X-TOTAL': '1',
    'X-Total-Pages': '1',
  };

  const mountComponent = ({ endpoint = defaultConfig.endpoint } = {}) => {
    wrapper = shallowMount(HarborTagsPage, {
      mocks: {
        $route,
      },
      provide() {
        return {
          breadCrumbState,
          endpoint,
        };
      },
    });
  };

  beforeEach(() => {
    mockHarborTagsResponse = Promise.resolve({
      data: harborTagsResponse,
      headers: defaultHeaders,
    });
  });

  it('contains tags header', () => {
    mountComponent();

    expect(findTagsHeader().exists()).toBe(true);
  });

  it('contains tags list', () => {
    mountComponent();

    expect(findTagsList().exists()).toBe(true);
  });

  describe('header', () => {
    it('has the correct props', async () => {
      mountComponent();

      await waitForHarborTagsRequest();
      expect(findTagsHeader().props()).toMatchObject({
        artifactDetail: mockArtifactDetail,
        pageInfo: {
          page: 1,
          perPage: 20,
          total: 1,
          totalPages: 1,
        },
        tagsLoading: false,
      });
    });
  });

  describe('list', () => {
    it('has the correct props', async () => {
      mountComponent();

      await waitForHarborTagsRequest();
      expect(findTagsList().props()).toMatchObject({
        tags: [
          {
            repositoryId: 4,
            artifactId: 5,
            id: 4,
            name: 'latest',
            pullTime: '0001-01-01T00:00:00.000Z',
            pushTime: '2022-05-27T18:21:27.903Z',
            signed: false,
            immutable: false,
          },
        ],
        isLoading: false,
        pageInfo: {
          page: 1,
          perPage: 20,
          total: 1,
          totalPages: 1,
        },
      });
    });
  });
});
