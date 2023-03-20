import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import HarborListHeader from '~/packages_and_registries/harbor_registry/components/list/harbor_list_header.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import {
  HARBOR_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  HARBOR_REGISTRY_HELP_PAGE_PATH,
} from '~/packages_and_registries/harbor_registry/constants/index';

describe('harbor_list_header', () => {
  let wrapper;

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findCommandsSlot = () => wrapper.find('[data-testid="commands-slot"]');
  const findImagesMetaDataItem = () => wrapper.findComponent(MetadataItem);

  const mountComponent = async (propsData, slots) => {
    wrapper = shallowMount(HarborListHeader, {
      stubs: {
        GlSprintf,
        TitleArea,
      },
      propsData,
      slots,
    });
    await nextTick();
  };

  describe('header', () => {
    it('has a title', () => {
      mountComponent({ metadataLoading: true });

      expect(findTitleArea().props()).toMatchObject({
        title: HARBOR_REGISTRY_TITLE,
        metadataLoading: true,
      });
    });

    it('has a commands slot', () => {
      mountComponent(null, { commands: '<div data-testid="commands-slot">baz</div>' });

      expect(findCommandsSlot().text()).toBe('baz');
    });

    describe('sub header parts', () => {
      describe('images count', () => {
        it('exists', async () => {
          await mountComponent({ imagesCount: 1 });

          expect(findImagesMetaDataItem().exists()).toBe(true);
        });

        it('when there is one image', async () => {
          await mountComponent({ imagesCount: 1 });

          expect(findImagesMetaDataItem().props()).toMatchObject({
            text: '1 Image repository',
            icon: 'container-image',
          });
        });

        it('when there is more than one image', async () => {
          await mountComponent({ imagesCount: 3 });

          expect(findImagesMetaDataItem().props('text')).toBe('3 Image repositories');
        });
      });
    });
  });

  describe('info messages', () => {
    describe('default message', () => {
      it('is correctly bound to title_area props', () => {
        mountComponent();

        expect(findTitleArea().props('infoMessages')).toEqual([
          { text: LIST_INTRO_TEXT, link: HARBOR_REGISTRY_HELP_PAGE_PATH },
        ]);
      });
    });
  });
});
