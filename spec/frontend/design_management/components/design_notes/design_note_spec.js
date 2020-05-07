import { shallowMount } from '@vue/test-utils';
import { ApolloMutation } from 'vue-apollo';
import DesignNote from '~/design_management/components/design_notes/design_note.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';

const scrollIntoViewMock = jest.fn();
const note = {
  id: 'gid://gitlab/DiffNote/123',
  author: {
    id: 'author-id',
  },
  body: 'test',
};
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const $route = {
  hash: '#note_123',
};

const mutate = jest.fn().mockResolvedValue({ data: { updateNote: {} } });

describe('Design note component', () => {
  let wrapper;

  const findUserAvatar = () => wrapper.find(UserAvatarLink);
  const findUserLink = () => wrapper.find('.js-user-link');
  const findReplyForm = () => wrapper.find(DesignReplyForm);
  const findEditButton = () => wrapper.find('.js-note-edit');
  const findNoteContent = () => wrapper.find('.js-note-text');

  function createComponent(props = {}, data = { isEditing: false }) {
    wrapper = shallowMount(DesignNote, {
      propsData: {
        note: {},
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('should match the snapshot', () => {
    createComponent({
      note,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('should render an author', () => {
    createComponent({
      note,
    });

    expect(findUserAvatar().exists()).toBe(true);
    expect(findUserLink().exists()).toBe(true);
  });

  it('should render a time ago tooltip if note has createdAt property', () => {
    createComponent({
      note: {
        ...note,
        createdAt: '2019-07-26T15:02:20Z',
      },
    });

    expect(wrapper.find(TimeAgoTooltip).exists()).toBe(true);
  });

  it('should trigger a scrollIntoView method', () => {
    createComponent({
      note,
    });

    expect(scrollIntoViewMock).toHaveBeenCalled();
  });

  it('should open an edit form on edit button click', () => {
    createComponent({
      note,
    });

    findEditButton().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(findReplyForm().exists()).toBe(true);
      expect(findNoteContent().exists()).toBe(false);
    });
  });

  describe('when edit form is rendered', () => {
    beforeEach(() => {
      createComponent(
        {
          note,
        },
        { isEditing: true },
      );
    });

    it('should not render note content and should render reply form', () => {
      expect(findNoteContent().exists()).toBe(false);
      expect(findReplyForm().exists()).toBe(true);
    });

    it('hides the form on hideForm event', () => {
      findReplyForm().vm.$emit('cancelForm');

      return wrapper.vm.$nextTick().then(() => {
        expect(findReplyForm().exists()).toBe(false);
        expect(findNoteContent().exists()).toBe(true);
      });
    });

    it('calls a mutation on submitForm event and hides a form', () => {
      findReplyForm().vm.$emit('submitForm');
      expect(mutate).toHaveBeenCalled();

      return mutate()
        .then(() => {
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(findReplyForm().exists()).toBe(false);
          expect(findNoteContent().exists()).toBe(true);
        });
    });
  });
});
