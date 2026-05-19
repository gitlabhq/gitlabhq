import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiStickyHeader from '~/wikis/components/wiki_sticky_header.vue';
import WikiSidebarToggle from '~/wikis/components/wiki_sidebar_toggle.vue';

describe('wikis/components/wiki_sticky_header', () => {
  let wrapper;

  const defaultProps = {
    isStickyHeaderShowing: true,
    pageHeading: 'Wiki page heading',
    showEditButton: true,
    wikiPage: {
      id: 'gid://gitlab/WikiPage/1',
      subscribed: false,
    },
  };

  function buildWrapper(props = {}, featureFlags = {}) {
    wrapper = shallowMountExtended(WikiStickyHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        glFeatures: featureFlags,
      },
    });
  }
  const findStickyHeader = () => wrapper.findByTestId('wiki-sticky-header');
  const findEditButton = () => wrapper.findByTestId('wiki-sticky-edit-button');
  const findSubscribeButton = () => wrapper.findByTestId('wiki-sticky-subscribe-button');
  const findSubscribeIcon = () => findSubscribeButton().findComponent(GlIcon);
  const findSidebarToggle = () => wrapper.findComponent(WikiSidebarToggle);

  describe('sidebar toggle', () => {
    it('renders the sidebar toggle', () => {
      buildWrapper({ isStickyHeaderShowing: true });

      expect(findSidebarToggle().exists()).toBe(true);
      expect(findSidebarToggle().props('action')).toBe('open');
    });
  });

  describe('visibility', () => {
    it('shows the sticky header when isStickyHeaderShowing is true', () => {
      buildWrapper({ isStickyHeaderShowing: true });

      expect(findStickyHeader().exists()).toBe(true);
    });

    it('hides the sticky header when isStickyHeaderShowing is false', () => {
      buildWrapper({ isStickyHeaderShowing: false });

      expect(findStickyHeader().exists()).toBe(false);
    });
  });

  describe('edit button', () => {
    it('renders edit button when showEditButton is true', () => {
      buildWrapper({ showEditButton: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('does not render edit button when showEditButton is false', () => {
      buildWrapper({ showEditButton: false });

      expect(findEditButton().exists()).toBe(false);
    });

    it('emits edit event when edit button is clicked', () => {
      buildWrapper();

      findEditButton().vm.$emit('click');

      expect(wrapper.emitted('edit')).toHaveLength(1);
    });
  });

  describe('subscribe button', () => {
    it('renders notifications-off icon when not subscribed', () => {
      buildWrapper({ wikiPage: { id: 'gid://gitlab/WikiPage/1', subscribed: false } });

      expect(findSubscribeIcon().props('name')).toBe('notifications-off');
    });

    it('renders notifications icon when subscribed', () => {
      buildWrapper({ wikiPage: { id: 'gid://gitlab/WikiPage/1', subscribed: true } });

      expect(findSubscribeIcon().props('name')).toBe('notifications');
    });

    it('disables subscribe button when wikiPage has no id', () => {
      buildWrapper({ wikiPage: {} });

      expect(findSubscribeButton().attributes('disabled')).toBeDefined();
    });

    it('emits toggle-subscribe event when subscribe button is clicked', () => {
      buildWrapper();

      findSubscribeButton().vm.$emit('click');

      expect(wrapper.emitted('toggle-subscribe')).toHaveLength(1);
    });

    it('applies info color class when subscribed', () => {
      buildWrapper({ wikiPage: { id: 'gid://gitlab/WikiPage/1', subscribed: true } });

      expect(findSubscribeIcon().classes()).toContain('!gl-text-status-info');
    });

    it('does not apply info color class when not subscribed', () => {
      buildWrapper({ wikiPage: { id: 'gid://gitlab/WikiPage/1', subscribed: false } });

      expect(findSubscribeIcon().classes()).not.toContain('!gl-text-status-info');
    });
  });
});
