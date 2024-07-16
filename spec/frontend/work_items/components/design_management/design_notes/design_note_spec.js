import { ApolloMutation } from 'vue-apollo';
import { GlAvatar, GlAvatarLink, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';

import DesignNote from '~/work_items/components/design_management/design_notes/design_note.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockAwardEmoji } from './mock_notes';

const scrollIntoViewMock = jest.fn();
const note = {
  id: 'gid://gitlab/DiffNote/123',
  author: {
    id: 'gid://gitlab/User/1',
    username: 'foo-bar',
    avatarUrl: 'https://gitlab.com/avatar',
    webUrl: 'https://gitlab.com/user',
  },
  awardEmoji: mockAwardEmoji,
  body: 'test',
  imported: false,
  userPermissions: {
    adminNote: false,
    awardEmoji: true,
  },
  createdAt: '2019-07-26T15:02:20Z',
};
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const $route = {
  hash: '#note_123',
};

describe('Design note component', () => {
  let wrapper;

  const findUserAvatar = () => wrapper.findComponent(GlAvatar);
  const findUserAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findUserLink = () => wrapper.findByTestId('user-link');
  const findEditButton = () => wrapper.findByTestId('note-edit');
  const findDropdown = () => wrapper.findByTestId('more-actions');

  const showToast = jest.fn();

  function createComponent({
    props = {},
    mocks = {
      $toast: {
        show: showToast,
      },
      $route,
      $apollo: {
        mutate: jest.fn().mockResolvedValue({ data: { updateNote: {} } }),
      },
    },
    stubs = {
      ApolloMutation,
      GlDisclosureDropdown,
      GlDisclosureDropdownItem,
      TimelineEntryItem: true,
      TimeAgoTooltip: true,
      GlAvatarLink: true,
      GlAvatar: true,
      GlLink: true,
    },
  } = {}) {
    wrapper = mountExtended(DesignNote, {
      propsData: {
        note: {},
        noteableId: 'gid://gitlab/DesignManagement::Design/6',
        designVariables: {
          atVersion: null,
          filenames: ['foo.jpg'],
          fullPath: 'gitlab-org/gitlab-test',
          iid: '1',
        },
        ...props,
      },
      provide: {
        issueIid: '1',
        projectPath: 'gitlab-org/gitlab-test',
      },
      mocks,
      stubs,
    });
  }

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent({ props: { note } });
    });

    it('should render avatar with correct props', () => {
      expect(findUserAvatar().props()).toMatchObject({
        src: note.author.avatarUrl,
        entityName: note.author.username,
      });

      expect(findUserAvatarLink().attributes()).toMatchObject({
        href: note.author.webUrl,
        'data-user-id': '1',
        'data-username': `${note.author.username}`,
      });
    });

    it('should render author details', () => {
      expect(findUserLink().exists()).toBe(true);
    });

    it('should render a time ago tooltip if note has createdAt property', () => {
      expect(wrapper.findComponent(TimeAgoTooltip).exists()).toBe(true);
    });

    it('should not render imported badge', () => {
      expect(findImportedBadge().exists()).toBe(false);
    });

    it('should not render edit icon when user does not have a permission', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('should not display a dropdown if user does not have a permission to delete note', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('should not have a `Deleted user` header', () => {
      expect(wrapper.text()).not.toContain('A deleted user');
    });
  });

  describe('when note has no author', () => {
    beforeEach(() => {
      createComponent({
        props: {
          note: {
            ...note,
            author: null,
          },
        },
      });
    });

    it('should not render author details', () => {
      expect(findUserLink().exists()).toBe(false);
    });

    it('should render a `Deleted user` header', () => {
      expect(wrapper.text()).toContain('A deleted user');
    });
  });

  describe('when note is imported', () => {
    it('should render imported badge', () => {
      createComponent({
        props: {
          note: {
            ...note,
            imported: true,
          },
        },
      });

      expect(findImportedBadge().props('importableType')).toBe('comment');
    });
  });
});
