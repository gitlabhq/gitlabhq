import { ApolloMutation } from 'vue-apollo';
import { GlAvatar, GlAvatarLink, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import createMockApollo from 'helpers/mock_apollo_helper';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { AWARD_EMOJI_TO_NOTE_ERROR } from '~/work_items/components/design_management/constants';
import DesignReplyForm from '~/work_items/components/design_management/design_notes/design_reply_form.vue';
import DesignNote from '~/work_items/components/design_management/design_notes/design_note.vue';
import designNoteAwardEmojiToggleMutation from '~/work_items/components/design_management/graphql/design_note_award_emoji_toggle.mutation.graphql';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { EMOJI_THUMBS_UP } from '~/emoji/constants';
import { getAwardEmojiResponse } from '../mock_data';
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
  const findDesignNoteAwardsList = () => wrapper.findComponent(AwardsList);
  const findReplyForm = () => wrapper.findComponent(DesignReplyForm);
  const findEmojiPicker = () => wrapper.findByTestId('note-emoji-button');
  const findEditButton = () => wrapper.findByTestId('note-edit');
  const findNoteContent = () => wrapper.findByTestId('note-text');
  const findDropdown = () => wrapper.findByTestId('more-actions');
  const findDropdownItems = () => findDropdown().findAllComponents(GlDisclosureDropdownItem);
  const findEditDropdownItem = () => findDropdownItems().at(0);
  const findCopyLinkDropdownItem = () => findDropdownItems().at(1);
  const findDeleteDropdownItem = () => findDropdownItems().at(2);

  const showToast = jest.fn();

  const awardEmojiAddSuccessHandler = jest.fn().mockResolvedValue(getAwardEmojiResponse(true));
  const awardEmojiUpdateFailureHandler = jest.fn().mockRejectedValue(new Error());

  function createComponent({
    awardEmojiMutationHandler = awardEmojiAddSuccessHandler,
    props = {},
    data = { isEditing: false },
    mocks = {
      $toast: {
        show: showToast,
      },
      $route,
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
    wrapper = shallowMountExtended(DesignNote, {
      apolloProvider: createMockApollo([
        [designNoteAwardEmojiToggleMutation, awardEmojiMutationHandler],
      ]),
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
      data() {
        return {
          ...data,
        };
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

    it('should render emoji awards list', () => {
      expect(findDesignNoteAwardsList().exists()).toBe(true);
    });

    it('should not render edit icon when user does not have a permission', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('should display action dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
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

  describe('when user has a permission to edit note', () => {
    it('should open an edit form on edit button click', async () => {
      createComponent({
        props: {
          note: {
            ...note,
            userPermissions: {
              adminNote: true,
              awardEmoji: true,
            },
          },
        },
      });

      findEditButton().vm.$emit('click');

      await nextTick();
      expect(findReplyForm().exists()).toBe(true);
      expect(findNoteContent().exists()).toBe(false);
    });

    describe('when edit form is rendered', () => {
      beforeEach(() => {
        createComponent({
          props: {
            note: {
              ...note,
              userPermissions: {
                adminNote: true,
                awardEmoji: true,
              },
            },
          },
          data: { isEditing: true },
        });
      });

      it('should open an edit form on edit button click', async () => {
        createComponent({
          props: {
            note: {
              ...note,
              userPermissions: {
                adminNote: true,
                awardEmoji: true,
              },
            },
          },
        });

        findEditDropdownItem().find('button').trigger('click');

        await nextTick();
        expect(findReplyForm().exists()).toBe(true);
        expect(findNoteContent().exists()).toBe(false);
      });

      it('should not render note content and should render reply form', () => {
        expect(findNoteContent().exists()).toBe(false);
        expect(findReplyForm().exists()).toBe(true);
      });

      it('hides the form on cancel-form event', async () => {
        findReplyForm().vm.$emit('cancel-form');

        await nextTick();
        expect(findReplyForm().exists()).toBe(false);
        expect(findNoteContent().exists()).toBe(true);
      });

      it('hides a form after update mutation is completed', async () => {
        findReplyForm().vm.$emit('note-submit-complete', { data: { updateNote: { errors: [] } } });

        await nextTick();
        expect(findReplyForm().exists()).toBe(false);
        expect(findNoteContent().exists()).toBe(true);
      });
    });
  });

  describe('when user has admin permissions', () => {
    it('should display a dropdown', () => {
      createComponent({
        props: {
          note: {
            ...note,
            userPermissions: {
              adminNote: true,
              awardEmoji: true,
            },
          },
        },
      });

      expect(findDropdown().exists()).toBe(true);
      expect(findEditDropdownItem().exists()).toBe(true);
      expect(findCopyLinkDropdownItem().exists()).toBe(true);
      expect(findDeleteDropdownItem().exists()).toBe(true);
      expect(findDropdown().props('items')[0].extraAttrs.class).toBe('sm:!gl-hidden');
    });
  });

  it('should emit `delete-note` event with proper payload when delete note button is clicked', () => {
    const payload = {
      ...note,
      userPermissions: {
        adminNote: true,
        awardEmoji: true,
      },
    };

    createComponent({
      props: {
        note: {
          ...payload,
        },
      },
    });

    findDeleteDropdownItem().find('button').trigger('click');

    expect(wrapper.emitted()).toEqual({ 'delete-note': [[{ ...payload }]] });
  });

  it('shows a success toast after copying the url to the clipboard', () => {
    createComponent({
      props: {
        note: {
          ...note,
          userPermissions: {
            adminNote: true,
            awardEmoji: false,
          },
        },
      },
    });

    findCopyLinkDropdownItem().find('button').trigger('click');

    expect(showToast).toHaveBeenCalledWith('Link copied to clipboard.');
  });

  it('has data-clipboard-text set to the correct url', () => {
    createComponent({
      props: {
        note: {
          ...note,
          userPermissions: {
            adminNote: true,
            awardEmoji: false,
          },
        },
      },
    });

    expect(findCopyLinkDropdownItem().props('item').extraAttrs['data-clipboard-text']).toBe(
      'http://test.host/#note_123',
    );
  });

  describe('when user has award emoji permissions', () => {
    const propsData = {
      note: {
        ...note,
        userPermissions: {
          adminNote: false,
          awardEmoji: true,
        },
      },
    };

    it('should render emoji-picker button', () => {
      createComponent({ props: propsData });

      expect(findEmojiPicker().exists()).toBe(true);
      expect(findEmojiPicker().props()).toMatchObject({
        right: false,
      });
    });

    it('should call mutation to add an emoji', async () => {
      createComponent({
        props: propsData,
        mocks: {
          $apollo: {
            mutate: awardEmojiAddSuccessHandler,
          },
        },
      });

      await waitForPromises();

      findEmojiPicker().vm.$emit('click', EMOJI_THUMBS_UP);

      expect(awardEmojiAddSuccessHandler).toHaveBeenCalled();
    });

    it('should emit an error when mutation fails', async () => {
      jest.spyOn(Sentry, 'captureException');
      createComponent({
        props: propsData,
        mocks: {
          $route,
          $apollo: {
            mutate: awardEmojiUpdateFailureHandler,
          },
        },
      });

      findEmojiPicker().vm.$emit('click', EMOJI_THUMBS_UP);

      expect(awardEmojiUpdateFailureHandler).toHaveBeenCalled();

      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalled();
      expect(wrapper.emitted('error')).toEqual([[AWARD_EMOJI_TO_NOTE_ERROR]]);
    });
  });
});
