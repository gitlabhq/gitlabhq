import { ApolloMutation } from 'vue-apollo';
import { nextTick } from 'vue';
import { GlAvatar, GlAvatarLink, GlDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignNote from '~/design_management/components/design_notes/design_note.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

const scrollIntoViewMock = jest.fn();
const note = {
  id: 'gid://gitlab/DiffNote/123',
  author: {
    id: 'gid://gitlab/User/1',
    username: 'foo-bar',
    avatarUrl: 'https://gitlab.com/avatar',
    webUrl: 'https://gitlab.com/user',
  },
  body: 'test',
  userPermissions: {
    adminNote: false,
  },
  createdAt: '2019-07-26T15:02:20Z',
};
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const $route = {
  hash: '#note_123',
};

const mutate = jest.fn().mockResolvedValue({ data: { updateNote: {} } });

describe('Design note component', () => {
  let wrapper;

  const findUserAvatar = () => wrapper.findComponent(GlAvatar);
  const findUserAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findUserLink = () => wrapper.findByTestId('user-link');
  const findReplyForm = () => wrapper.findComponent(DesignReplyForm);
  const findEditButton = () => wrapper.findByTestId('note-edit');
  const findNoteContent = () => wrapper.findByTestId('note-text');
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDeleteNoteButton = () => wrapper.find('[data-testid="delete-note-button"]');

  function createComponent(props = {}, data = { isEditing: false }) {
    wrapper = shallowMountExtended(DesignNote, {
      propsData: {
        note: {},
        noteableId: 'gid://gitlab/DesignManagement::Design/6',
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      mocks: {
        $route,
        $apollo: {
          mutate,
        },
      },
      stubs: {
        ApolloMutation,
      },
    });
  }

  it('should match the snapshot', () => {
    createComponent({
      note,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('should render avatar with correct props', () => {
    createComponent({
      note,
    });

    expect(findUserAvatar().props()).toMatchObject({
      src: note.author.avatarUrl,
      entityName: note.author.username,
    });

    expect(findUserAvatarLink().attributes('href')).toBe(note.author.webUrl);
  });

  it('should render author details', () => {
    createComponent({
      note,
    });

    expect(findUserLink().exists()).toBe(true);
  });

  it('should render a time ago tooltip if note has createdAt property', () => {
    createComponent({
      note,
    });

    expect(wrapper.findComponent(TimeAgoTooltip).exists()).toBe(true);
  });

  it('should not render edit icon when user does not have a permission', () => {
    createComponent({
      note,
    });

    expect(findEditButton().exists()).toBe(false);
  });

  it('should not display a dropdown if user does not have a permission to delete note', () => {
    createComponent({
      note,
    });

    expect(findDropdown().exists()).toBe(false);
  });

  describe('when user has a permission to edit note', () => {
    it('should open an edit form on edit button click', async () => {
      createComponent({
        note: {
          ...note,
          userPermissions: {
            adminNote: true,
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
        createComponent(
          {
            note: {
              ...note,
              userPermissions: {
                adminNote: true,
              },
            },
          },
          { isEditing: true },
        );
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

  describe('when user has a permission to delete note', () => {
    it('should display a dropdown', () => {
      createComponent({
        note: {
          ...note,
          userPermissions: {
            adminNote: true,
          },
        },
      });

      expect(findDropdown().exists()).toBe(true);
    });
  });

  it('should emit `delete-note` event with proper payload when delete note button is clicked', () => {
    const payload = {
      ...note,
      userPermissions: {
        adminNote: true,
      },
    };

    createComponent({
      note: {
        ...payload,
      },
    });

    findDeleteNoteButton().vm.$emit('click');

    expect(wrapper.emitted()).toEqual({ 'delete-note': [[{ ...payload }]] });
  });
});
