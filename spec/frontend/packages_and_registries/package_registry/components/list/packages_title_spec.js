import { shallowMount } from '@vue/test-utils';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('PackageTitle', () => {
  let wrapper;
  let store;

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findMetadataItem = () => wrapper.findComponent(MetadataItem);

  const mountComponent = (propsData = { helpUrl: 'foo' }) => {
    wrapper = shallowMount(PackageTitle, {
      store,
      propsData,
      stubs: {
        TitleArea,
      },
    });
  };

  describe('title area', () => {
    it('exists', () => {
      mountComponent();

      expect(findTitleArea().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findTitleArea().props()).toMatchObject({
        title: PackageTitle.i18n.LIST_TITLE_TEXT,
        infoMessages: [],
      });
    });
  });

  describe.each`
    count        | exist    | text
    ${null}      | ${false} | ${''}
    ${undefined} | ${false} | ${''}
    ${0}         | ${true}  | ${'0 Packages'}
    ${1}         | ${true}  | ${'1 Package'}
    ${2}         | ${true}  | ${'2 Packages'}
  `('when count is $count metadata item', ({ count, exist, text }) => {
    beforeEach(() => {
      mountComponent({ count, helpUrl: 'foo' });
    });

    it(`is ${exist} that it exists`, () => {
      expect(findMetadataItem().exists()).toBe(exist);
    });

    if (exist) {
      it('has the correct props', () => {
        expect(findMetadataItem().props()).toMatchObject({
          icon: 'package',
          text,
        });
      });
    }
  });
});
