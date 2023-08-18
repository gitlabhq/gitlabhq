import { shallowMount } from '@vue/test-utils';
import Component from '~/packages_and_registries/container_registry/explorer/components/list_page/image_list.vue';
import ImageListRow from '~/packages_and_registries/container_registry/explorer/components/list_page/image_list_row.vue';

import { imagesListResponse } from '../../mock_data';

describe('Image List', () => {
  let wrapper;

  const findRow = () => wrapper.findAllComponents(ImageListRow);

  const mountComponent = (props) => {
    wrapper = shallowMount(Component, {
      propsData: {
        images: imagesListResponse,
        ...props,
      },
    });
  };

  describe('list', () => {
    it('contains one list element for each image', () => {
      mountComponent();

      expect(findRow().length).toBe(imagesListResponse.length);
    });

    it('when delete event is emitted on the row it emits up a delete event', () => {
      mountComponent();

      findRow().at(0).vm.$emit('delete', 'foo');
      expect(wrapper.emitted('delete')).toEqual([['foo']]);
    });

    it('passes down the metadataLoading prop', () => {
      mountComponent({ metadataLoading: true });
      expect(findRow().at(0).props('metadataLoading')).toBe(true);
    });
  });
});
