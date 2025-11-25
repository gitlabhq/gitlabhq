import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlLoadingIcon } from '@gitlab/ui';
import NoteHeader from '~/rapid_diffs/app/discussions/note_header.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('NoteHeader', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NoteHeader, {
      propsData: props,
    });
  };

  const findAuthorLink = () => wrapper.find('a[data-username]');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findInternalNoteBadge = () => wrapper.findComponent(GlBadge);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('author', () => {
    it('shows author name and username', () => {
      const author = {
        id: 'gid://gitlab/User/123',
        name: 'John Doe',
        username: 'johndoe',
        path: '/johndoe',
      };
      createComponent({ author });
      const authorLink = findAuthorLink();
      expect(authorLink.exists()).toBe(true);
      expect(authorLink.attributes('href')).toBe('/johndoe');
      expect(authorLink.attributes('data-user-id')).toBe('123');
      expect(authorLink.attributes('data-username')).toBe('johndoe');
      expect(authorLink.text()).toContain('John Doe');
      expect(authorLink.text()).toContain('@johndoe');
    });

    it('uses webUrl when path is not available', () => {
      const author = {
        id: 'gid://gitlab/User/123',
        name: 'John Doe',
        username: 'johndoe',
        webUrl: 'https://example.com/johndoe',
      };
      createComponent({ author });
      expect(findAuthorLink().attributes('href')).toBe('https://example.com/johndoe');
    });

    it('does not show username for system notes', () => {
      const author = {
        id: 'gid://gitlab/User/123',
        name: 'John Doe',
        username: 'johndoe',
        path: '/johndoe',
      };
      createComponent({ author, isSystemNote: true });
      expect(wrapper.text()).not.toContain(author.username);
    });

    it('shows username for non-system notes', () => {
      const author = {
        id: 'gid://gitlab/User/123',
        name: 'John Doe',
        username: 'johndoe',
        path: '/johndoe',
      };
      createComponent({ author, isSystemNote: false });
      expect(wrapper.text()).toContain(author.username);
    });

    it('shows deleted user message instead of user link when no author is provided', () => {
      createComponent({ author: null });
      expect(findAuthorLink().exists()).toBe(false);
      expect(wrapper.text()).toContain('A deleted user');
    });
  });

  describe('timestamp', () => {
    it('does not show timestamp when createdAt is null', () => {
      createComponent({ createdAt: null });
      expect(findTimeAgoTooltip().exists()).toBe(false);
    });

    it('shows timestamp without link when noteId is not provided', () => {
      createComponent({ createdAt: '2024-01-01T10:00:00Z' });
      const tooltip = findTimeAgoTooltip();
      expect(tooltip.exists()).toBe(true);
      expect(tooltip.props('time')).toBe('2024-01-01T10:00:00Z');
      expect(tooltip.props('tooltipPlacement')).toBe('bottom');
      expect(tooltip.props('href')).toBe('');
    });

    it('shows timestamp with link when noteId is provided', () => {
      createComponent({ createdAt: '2024-01-01T10:00:00Z', noteId: '456' });
      const tooltip = findTimeAgoTooltip();
      expect(tooltip.exists()).toBe(true);
      expect(tooltip.attributes('href')).toBe('#note_456');
    });

    it('converts GraphQL ID to numeric ID for link', () => {
      createComponent({ createdAt: '2024-01-01T10:00:00Z', noteId: 'gid://gitlab/Note/789' });
      expect(findTimeAgoTooltip().attributes('href')).toBe('#note_789');
    });

    it('uses noteUrl when provided', () => {
      createComponent({
        createdAt: '2024-01-01T10:00:00Z',
        noteId: '456',
        noteUrl: '/custom/url',
      });
      expect(findTimeAgoTooltip().attributes('href')).toBe('/custom/url');
    });
  });

  describe('action text', () => {
    it('shows action text when provided', () => {
      createComponent({ createdAt: '2024-01-01T10:00:00Z', actionText: 'commented' });
      expect(wrapper.text()).toContain('commented');
    });
  });

  describe('imported badge', () => {
    it('does not show when isImported is false', () => {
      createComponent({ isImported: false });
      expect(findImportedBadge().exists()).toBe(false);
    });

    it('shows when isImported is true', () => {
      createComponent({ isImported: true });
      expect(findImportedBadge().exists()).toBe(true);
    });

    it('shows text-only badge for system notes', () => {
      createComponent({ isImported: true, isSystemNote: true });
      expect(findImportedBadge().props('textOnly')).toBe(true);
    });

    it('shows full badge for non-system notes', () => {
      createComponent({ isImported: true, isSystemNote: false });
      expect(findImportedBadge().props('textOnly')).toBe(false);
    });
  });

  describe('internal note badge', () => {
    it('does not show when isInternalNote is false', () => {
      createComponent({ isInternalNote: false });
      expect(findInternalNoteBadge().exists()).toBe(false);
    });

    it('shows when isInternalNote is true', () => {
      createComponent({ isInternalNote: true });
      const badge = findInternalNoteBadge();
      expect(badge.props('variant')).toBe('warning');
      expect(badge.text()).toBe('Internal note');
      expect(badge.attributes('title')).toBe('This internal note will always remain confidential');
    });
  });

  describe('loading icon', () => {
    it('does not show when isUpdating is false', () => {
      createComponent({ isUpdating: false });
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows when isUpdating is true', () => {
      createComponent({ isUpdating: true });
      const loadingIcon = findLoadingIcon();
      expect(loadingIcon.exists()).toBe(true);
      expect(loadingIcon.props('size')).toBe('sm');
      expect(loadingIcon.props('label')).toBe('Comment is being updated');
    });
  });
});
