import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ToolbarItem from '~/static_site_editor/rich_content_editor/toolbar_item.vue';

describe('Toolbar Item', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const findButton = () => wrapper.find('button');

  const buildWrapper = (propsData) => {
    wrapper = shallowMount(ToolbarItem, {
      propsData,
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  describe.each`
    icon               | tooltip
    ${'heading'}       | ${'Headings'}
    ${'bold'}          | ${'Add bold text'}
    ${'italic'}        | ${'Add italic text'}
    ${'strikethrough'} | ${'Add strikethrough text'}
    ${'quote'}         | ${'Insert a quote'}
    ${'link'}          | ${'Add a link'}
    ${'doc-code'}      | ${'Insert a code block'}
    ${'list-bulleted'} | ${'Add a bullet list'}
    ${'list-numbered'} | ${'Add a numbered list'}
    ${'list-task'}     | ${'Add a task list'}
    ${'list-indent'}   | ${'Indent'}
    ${'list-outdent'}  | ${'Outdent'}
    ${'dash'}          | ${'Add a line'}
    ${'table'}         | ${'Add a table'}
    ${'code'}          | ${'Insert an image'}
    ${'code'}          | ${'Insert inline code'}
  `('toolbar item component', ({ icon, tooltip }) => {
    beforeEach(() => buildWrapper({ icon, tooltip }));

    it('renders a toolbar button', () => {
      expect(findButton().exists()).toBe(true);
    });

    it('renders the correct tooltip', () => {
      const buttonTooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(buttonTooltip).toBeDefined();
      expect(buttonTooltip.value.title).toBe(tooltip);
    });

    it(`renders the ${icon} icon`, () => {
      expect(findIcon().exists()).toBe(true);
      expect(findIcon().props().name).toBe(icon);
    });
  });
});
