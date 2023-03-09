import { shallowMount } from '@vue/test-utils';
import TagsList from '~/packages_and_registries/harbor_registry/components/tags/tags_list.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import TagsListRow from '~/packages_and_registries/harbor_registry/components/tags/tags_list_row.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import { defaultConfig, harborTagsResponse } from '../../mock_data';

describe('Harbor Tags List', () => {
  let wrapper;

  const findTagsLoader = () => wrapper.findComponent(TagsLoader);
  const findTagsListRows = () => wrapper.findAllComponents(TagsListRow);
  const findRegistryList = () => wrapper.findComponent(RegistryList);

  const mountComponent = ({ propsData, config = defaultConfig }) => {
    wrapper = shallowMount(TagsList, {
      propsData,
      stubs: { RegistryList },
      provide() {
        return {
          ...config,
        };
      },
    });
  };

  describe('when isLoading is true', () => {
    beforeEach(() => {
      mountComponent({
        propsData: {
          isLoading: true,
          pageInfo: {},
          tags: [],
        },
      });
    });

    it('show the loader', () => {
      expect(findTagsLoader().exists()).toBe(true);
    });
  });

  describe('tags list', () => {
    beforeEach(() => {
      mountComponent({
        propsData: {
          isLoading: false,
          pageInfo: {},
          tags: harborTagsResponse,
        },
      });
    });

    it('should render correctly', () => {
      expect(findRegistryList().exists()).toBe(true);
    });

    it('one tag row exists', () => {
      expect(findTagsListRows()).toHaveLength(harborTagsResponse.length);
    });
  });
});
