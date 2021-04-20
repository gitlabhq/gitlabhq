import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/infrastructure_registry/components/infrastructure_title.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('Infrastructure Title', () => {
  let wrapper;
  let store;

  const findTitleArea = () => wrapper.find(TitleArea);
  const findMetadataItem = () => wrapper.find(MetadataItem);

  const mountComponent = (propsData = { helpUrl: 'foo' }) => {
    wrapper = shallowMount(component, {
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
        title: 'Infrastructure Registry',
        infoMessages: [
          {
            text: 'Publish and share your modules. %{docLinkStart}More information%{docLinkEnd}',
            link: 'foo',
          },
        ],
      });
    });
  });

  describe.each`
    count        | exist    | text
    ${null}      | ${false} | ${''}
    ${undefined} | ${false} | ${''}
    ${0}         | ${true}  | ${'0 Modules'}
    ${1}         | ${true}  | ${'1 Module'}
    ${2}         | ${true}  | ${'2 Modules'}
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
          icon: 'infrastructure-registry',
          text,
        });
      });
    }
  });
});
