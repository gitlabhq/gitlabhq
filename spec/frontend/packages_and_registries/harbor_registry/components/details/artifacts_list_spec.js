import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import ArtifactsList from '~/packages_and_registries/harbor_registry/components/details/artifacts_list.vue';
import ArtifactsListRow from '~/packages_and_registries/harbor_registry/components/details/artifacts_list_row.vue';
import { defaultConfig, harborArtifactsList } from '../../mock_data';

describe('Harbor artifacts list', () => {
  let wrapper;

  const findTagsLoader = () => wrapper.findComponent(TagsLoader);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findArtifactsListRow = () => wrapper.findAllComponents(ArtifactsListRow);

  const mountComponent = ({ propsData, config = defaultConfig }) => {
    wrapper = shallowMount(ArtifactsList, {
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
          filter: '',
          artifacts: [],
        },
      });
    });

    it('show the loader', () => {
      expect(findTagsLoader().exists()).toBe(true);
    });

    it('does not show the list', () => {
      expect(findGlEmptyState().exists()).toBe(false);
      expect(findRegistryList().exists()).toBe(false);
    });
  });

  describe('registry list', () => {
    beforeEach(() => {
      mountComponent({
        propsData: {
          isLoading: false,
          pageInfo: {},
          filter: '',
          artifacts: harborArtifactsList,
        },
      });
    });

    it('exists', () => {
      expect(findRegistryList().exists()).toBe(true);
    });

    it('one artifact row exist', () => {
      expect(findArtifactsListRow()).toHaveLength(harborArtifactsList.length);
    });
  });
});
