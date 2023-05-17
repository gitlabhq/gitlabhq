import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/infrastructure_registry/list/components/infrastructure_title.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

describe('Infrastructure Title', () => {
  let wrapper;
  let store;

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findMetadataItem = () => wrapper.findComponent(MetadataItem);

  const exampleProps = { helpUrl: 'http://example.gitlab.com/help' };

  const mountComponent = (propsData = exampleProps) => {
    wrapper = shallowMount(component, {
      store,
      propsData,
      stubs: {
        TitleArea,
      },
    });
  };

  describe('title area', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findTitleArea().exists()).toBe(true);
    });

    it('has the correct title', () => {
      expect(findTitleArea().props('title')).toBe('Terraform Module Registry');
    });

    describe('with no modules', () => {
      it('has no info message', () => {
        expect(findTitleArea().props('infoMessages')).toStrictEqual([]);
      });
    });

    describe('with at least one module', () => {
      beforeEach(() => {
        mountComponent({ ...exampleProps, count: 1 });
      });

      it('has an info message', () => {
        expect(findTitleArea().props('infoMessages')).toStrictEqual([
          {
            text: 'Publish and share your modules. %{docLinkStart}More information%{docLinkEnd}',
            link: exampleProps.helpUrl,
          },
        ]);
      });
    });
  });

  describe.each`
    count        | exist    | text
    ${null}      | ${false} | ${''}
    ${undefined} | ${false} | ${''}
    ${0}         | ${false} | ${''}
    ${1}         | ${true}  | ${'1 Module'}
    ${2}         | ${true}  | ${'2 Modules'}
  `('when count is $count metadata item', ({ count, exist, text }) => {
    beforeEach(() => {
      mountComponent({ ...exampleProps, count });
    });

    it(`${exist ? 'exists' : 'does not exist'}`, () => {
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
