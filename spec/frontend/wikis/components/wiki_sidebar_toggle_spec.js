import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiSidebarToggle from '~/wikis/components/wiki_sidebar_toggle.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';
import { assertProps } from 'helpers/assert_props';

// Mock the toggleWikiSidebar function
jest.mock('~/wikis/utils/sidebar_toggle', () => ({
  toggleWikiSidebar: jest.fn(),
}));

describe('WikiSidebarToggle', () => {
  let wrapper;

  const createComponent = (props = { action: 'open' }) => {
    wrapper = shallowMountExtended(WikiSidebarToggle, {
      propsData: props,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const getGlButton = () => wrapper.getComponent(GlButton);

  describe.each`
    action     | icon                        | title
    ${'open'}  | ${'list-bulleted'}          | ${'Open sidebar'}
    ${'close'} | ${'chevron-double-lg-left'} | ${'Close sidebar'}
  `('when action=$action', ({ action, icon, title }) => {
    beforeEach(() => {
      createComponent({ action });
    });

    it('shows the correct icon', () => {
      expect(getGlButton().props('icon')).toBe(icon);
    });

    it('calls the correct handler', async () => {
      getGlButton().vm.$emit('click');
      await nextTick();

      expect(toggleWikiSidebar).toHaveBeenCalledTimes(1);
    });

    it('has the correct title', () => {
      expect(getGlButton().attributes('title')).toBe(title);
    });
  });

  describe.each(['open', 'close'])("when action prop is valid ('%s')", (action) => {
    it('does not throw an error', () => {
      expect(() => {
        assertProps(WikiSidebarToggle, { action });
      }).not.toThrow();
    });
  });

  describe('when action prop is invalid', () => {
    it('throws an error', () => {
      expect(() => {
        assertProps(WikiSidebarToggle, { action: 'foo' });
      }).toThrow();
    });
  });

  it('checks that tooltip is displayed', () => {
    createComponent();

    expect(getBinding(getGlButton().element, 'gl-tooltip')).not.toBe(undefined);
  });
});
