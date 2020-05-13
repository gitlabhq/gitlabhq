import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import ToolbarItem from '~/vue_shared/components/rich_content_editor/toolbar_item.vue';

describe('Toolbar Item', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const findButton = () => wrapper.find('button');

  const buildWrapper = propsData => {
    wrapper = shallowMount(ToolbarItem, { propsData });
  };

  describe.each`
    icon
    ${'heading'}
    ${'bold'}
    ${'italic'}
    ${'strikethrough'}
    ${'quote'}
    ${'link'}
    ${'doc-code'}
    ${'list-bulleted'}
    ${'list-numbered'}
    ${'list-task'}
    ${'list-indent'}
    ${'list-outdent'}
    ${'dash'}
    ${'table'}
    ${'code'}
  `('toolbar item component', ({ icon }) => {
    beforeEach(() => buildWrapper({ icon }));

    it('renders a toolbar button', () => {
      expect(findButton().exists()).toBe(true);
    });

    it(`renders the ${icon} icon`, () => {
      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props().name).toBe(icon);
    });
  });
});
