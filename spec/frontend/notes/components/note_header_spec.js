import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteHeader from '~/notes/components/note_header.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

Vue.use(Vuex);

const actions = {
  setTargetNoteHash: jest.fn(),
};

describe('NoteHeader component', () => {
  let wrapper;

  const findActionText = () => wrapper.findComponent({ ref: 'actionText' });
  const findTimestampLink = () => wrapper.findComponent({ ref: 'noteTimestampLink' });
  const findTimestamp = () => wrapper.findComponent({ ref: 'noteTimestamp' });
  const findInternalNoteIndicator = () => wrapper.findByTestId('internal-note-indicator');
  const findAuthorName = () => wrapper.findByTestId('author-name');
  const findSpinner = () => wrapper.findComponent({ ref: 'spinner' });
  const authorUsernameLink = () => wrapper.findComponent({ ref: 'authorUsernameLink' });
  const findAuthorNameLink = () => wrapper.findComponent({ ref: 'authorNameLink' });
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);

  const statusHtml =
    '"<span class="user-status-emoji has-tooltip" title="foo bar" data-html="true" data-placement="top"><gl-emoji title="basketball and hoop" data-name="basketball" data-unicode-version="6.0">🏀</gl-emoji></span>"';

  const author = {
    avatar_url: null,
    id: 1,
    name: 'Root',
    path: '/root',
    state: 'active',
    username: 'root',
    show_status: true,
    status_tooltip_html: statusHtml,
  };

  const supportBotAuthor = {
    avatar_url: null,
    id: 1,
    name: 'Gitlab Support Bot',
    path: '/support-bot',
    state: 'active',
    username: 'support-bot',
    show_status: true,
    status_tooltip_html: statusHtml,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(NoteHeader, {
      store: new Vuex.Store({
        actions,
      }),
      propsData: { ...props },
    });
  };

  it('renders an author link if author is passed to props', () => {
    createComponent({ author });

    expect(wrapper.find('.js-user-link').exists()).toBe(true);
  });
  it('renders deleted user text if author is not passed as a prop', () => {
    createComponent();

    expect(wrapper.text()).toContain('A deleted user');
  });

  it('renders participant email when author is a support-bot', () => {
    createComponent({
      author: supportBotAuthor,
      emailParticipant: 'email@example.com',
    });

    expect(findAuthorName().text()).toBe('email@example.com');
    expect(authorUsernameLink().exists()).toBe(false);
  });

  it('does not render created at information if createdAt is not passed as a prop', () => {
    createComponent();

    expect(findActionText().exists()).toBe(false);
    expect(findTimestampLink().exists()).toBe(false);
  });

  describe('when createdAt is passed as a prop', () => {
    it('renders action text and a timestamp', () => {
      createComponent({
        createdAt: '2017-08-02T10:51:58.559Z',
        noteId: 123,
      });

      expect(findActionText().exists()).toBe(true);
      expect(findTimestampLink().exists()).toBe(true);
    });

    it('renders correct actionText if passed', () => {
      createComponent({
        createdAt: '2017-08-02T10:51:58.559Z',
        actionText: 'Test action text',
      });

      expect(findActionText().text()).toBe('Test action text');
    });

    it('calls an action when timestamp is clicked', () => {
      createComponent({
        createdAt: '2017-08-02T10:51:58.559Z',
        noteId: 123,
      });
      findTimestampLink().trigger('click');

      expect(actions.setTargetNoteHash).toHaveBeenCalled();
    });
  });

  describe('loading spinner', () => {
    it('shows spinner when showSpinner is true', () => {
      createComponent();
      expect(findSpinner().exists()).toBe(true);
    });

    it('does not show spinner when showSpinner is false', () => {
      createComponent({ showSpinner: false });
      expect(findSpinner().exists()).toBe(false);
    });
  });

  describe('timestamp', () => {
    it('shows timestamp as a link if a noteId was provided', () => {
      createComponent({ createdAt: new Date().toISOString(), noteId: 123 });
      expect(findTimestampLink().exists()).toBe(true);
      expect(findTimestamp().exists()).toBe(false);
    });

    it('generates correct link for alphanumeric noteId', () => {
      createComponent({
        createdAt: new Date().toISOString(),
        noteId: 'afccb75d1ce204bd6f96c3a58dfb4be906b14a6e',
      });
      expect(findTimestampLink().attributes('href')).toBe(
        '#note_afccb75d1ce204bd6f96c3a58dfb4be906b14a6e',
      );
    });

    it('generates correct link for GraphQL GID', () => {
      createComponent({ createdAt: new Date().toISOString(), noteId: 'gid://gitlab/Note/123' });
      expect(findTimestampLink().attributes('href')).toBe('#note_123');
    });

    it('shows timestamp as plain text if a noteId was not provided', () => {
      createComponent({ createdAt: new Date().toISOString() });
      expect(findTimestampLink().exists()).toBe(false);
      expect(findTimestamp().exists()).toBe(true);
    });
  });

  describe('author username link', () => {
    it('proxies `mouseenter` event to author name link', () => {
      createComponent({ author });

      const dispatchEvent = jest.spyOn(findAuthorNameLink().element, 'dispatchEvent');

      wrapper.findComponent({ ref: 'authorUsernameLink' }).trigger('mouseenter');

      expect(dispatchEvent).toHaveBeenCalledWith(new Event('mouseenter'));
    });

    it('proxies `mouseleave` event to author name link', () => {
      createComponent({ author });

      const dispatchEvent = jest.spyOn(findAuthorNameLink().element, 'dispatchEvent');

      wrapper.findComponent({ ref: 'authorUsernameLink' }).trigger('mouseleave');

      expect(dispatchEvent).toHaveBeenCalledWith(new Event('mouseleave'));
    });
  });

  describe('when author username link is hovered', () => {
    it('toggles hover specific CSS classes on author name link', async () => {
      createComponent({ author });

      const authorNameLink = wrapper.findComponent({ ref: 'authorNameLink' });

      authorUsernameLink().trigger('mouseenter');

      await nextTick();
      expect(authorNameLink.classes()).toContain('hover');
      expect(authorNameLink.classes()).toContain('text-underline');

      authorUsernameLink().trigger('mouseleave');

      await nextTick();
      expect(authorNameLink.classes()).not.toContain('hover');
      expect(authorNameLink.classes()).not.toContain('text-underline');
    });
  });

  describe('imported badge', () => {
    it('renders with "comment" when note is imported', () => {
      createComponent({ isImported: true });

      expect(findImportedBadge().props('importableType')).toBe('comment');
    });

    it('renders with "activity" when note is imported and is system note', () => {
      createComponent({ isImported: true, isSystemNote: true });

      expect(findImportedBadge().props('importableType')).toBe('activity');
    });

    it('does not render when note is not imported', () => {
      createComponent({ isImported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });

  describe('with internal note badge', () => {
    it.each`
      status   | condition
      ${true}  | ${'shows'}
      ${false} | ${'hides'}
    `('$condition badge when isInternalNote is $status', ({ status }) => {
      createComponent({ isInternalNote: status });
      expect(findInternalNoteIndicator().exists()).toBe(status);
    });

    it('shows internal note badge tooltip for project context', () => {
      createComponent({ isInternalNote: true, noteableType: 'issue' });

      expect(findInternalNoteIndicator().attributes('title')).toBe(
        'This internal note will always remain confidential',
      );
    });
  });

  it('does render username', () => {
    createComponent({ author }, true);

    expect(wrapper.find('.note-header-info').text()).toContain('@');
  });

  describe('with system note', () => {
    it('does not render username', () => {
      createComponent({ author, isSystemNote: true }, true);

      expect(wrapper.find('.note-header-info').text()).not.toContain('@');
    });
  });
});
