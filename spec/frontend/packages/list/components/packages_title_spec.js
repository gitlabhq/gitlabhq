import { shallowMount } from '@vue/test-utils';
import { LIST_INTRO_TEXT, LIST_TITLE_TEXT } from '~/packages/list//constants';
import PackageTitle from '~/packages/list/components/package_title.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('PackageTitle', () => {
  let wrapper;
  let store;

  const findTitleArea = () => wrapper.find(TitleArea);
  const findMetadataItem = () => wrapper.find(MetadataItem);

  const mountComponent = (propsData = { helpUrl: 'foo' }) => {
    wrapper = shallowMount(PackageTitle, {
      store,
      propsData,
      stubs: {
        TitleArea,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('title area', () => {
    it('exists', () => {
      mountComponent();

      expect(findTitleArea().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findTitleArea().props()).toMatchObject({
        title: LIST_TITLE_TEXT,
        infoMessages: [{ text: LIST_INTRO_TEXT, link: 'foo' }],
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
