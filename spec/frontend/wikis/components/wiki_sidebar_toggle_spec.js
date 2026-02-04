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

  const createComponent = (props = { action: 'open' }, provide = {}) => {
    wrapper = shallowMountExtended(WikiSidebarToggle, {
      propsData: props,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide,
    });
  };

  const getGlButton = () => wrapper.getComponent(GlButton);

  describe.each`
    action     | wikiFloatingSidebarToggle | icon                        | buttonCategory | title              | cssClass
    ${'open'}  | ${false}                  | ${'list-bulleted'}          | ${'tertiary'}  | ${'Open sidebar'}  | ${'toggle-action-open'}
    ${'close'} | ${false}                  | ${'chevron-double-lg-left'} | ${'tertiary'}  | ${'Close sidebar'} | ${'toggle-action-close'}
    ${'open'}  | ${true}                   | ${'sidebar'}                | ${'secondary'} | ${'Open sidebar'}  | ${'toggle-action-open'}
    ${'close'} | ${true}                   | ${'chevron-double-lg-left'} | ${'tertiary'}  | ${'Close sidebar'} | ${'toggle-action-close'}
  `(
    'when action=$action and feature wikiFloatingSidebarToggle=$wikiFloatingSidebarToggle',
    ({ action, wikiFloatingSidebarToggle, icon, title, buttonCategory, cssClass }) => {
      beforeEach(() => {
        createComponent(
          { action },
          {
            glFeatures: { wikiFloatingSidebarToggle },
          },
        );
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

      it('button has the correct category', () => {
        expect(getGlButton().props('category')).toBe(buttonCategory);
      });

      it('has the correct CSS class', () => {
        expect(getGlButton().classes()).toContain('wiki-sidebar-toggle');
        expect(getGlButton().classes()).toContain(cssClass);
      });
    },
  );

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
