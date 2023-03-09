import { shallowMount } from '@vue/test-utils';
import HarborList from '~/packages_and_registries/harbor_registry/components/list/harbor_list.vue';
import HarborListRow from '~/packages_and_registries/harbor_registry/components/list/harbor_list_row.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import { harborImagesList } from '../../mock_data';

describe('Harbor List', () => {
  let wrapper;

  const findHarborListRow = () => wrapper.findAllComponents(HarborListRow);

  const mountComponent = (props) => {
    wrapper = shallowMount(HarborList, {
      stubs: { RegistryList },
      propsData: {
        images: harborImagesList,
        pageInfo: {},
        ...props,
      },
    });
  };

  describe('list', () => {
    it('contains one list element for each image', () => {
      mountComponent();

      expect(findHarborListRow().length).toBe(harborImagesList.length);
    });

    it('passes down the metadataLoading prop', () => {
      mountComponent({ metadataLoading: true });
      expect(findHarborListRow().at(0).props('metadataLoading')).toBe(true);
    });
  });
});
