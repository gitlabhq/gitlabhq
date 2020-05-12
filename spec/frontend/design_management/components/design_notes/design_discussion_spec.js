import { shallowMount } from '@vue/test-utils';
import { ApolloMutation } from 'vue-apollo';
import DesignDiscussion from '~/design_management/components/design_notes/design_discussion.vue';
import DesignNote from '~/design_management/components/design_notes/design_note.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import createNoteMutation from '~/design_management/graphql/mutations/createNote.mutation.graphql';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';

describe('Design discussions component', () => {
  let wrapper;

  const findReplyPlaceholder = () => wrapper.find(ReplyPlaceholder);
  const findReplyForm = () => wrapper.find(DesignReplyForm);

  const mutationVariables = {
    mutation: createNoteMutation,
    update: expect.anything(),
    variables: {
      input: {
        noteableId: 'noteable-id',
        body: 'test',
        discussionId: '0',
      },
    },
  };
  const mutate = jest.fn(() => Promise.resolve());
  const $apollo = {
    mutate,
  };

  function createComponent(props = {}) {
    wrapper = shallowMount(DesignDiscussion, {
      propsData: {
        discussion: {
          id: '0',
          notes: [
            {
              id: '1',
            },
            {
              id: '2',
            },
          ],
        },
        noteableId: 'noteable-id',
        designId: 'design-id',
        discussionIndex: 1,
        ...props,
      },
      stubs: {
        ReplyPlaceholder,
        ApolloMutation,
      },
      mocks: { $apollo },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders correct amount of discussion notes', () => {
    expect(wrapper.findAll(DesignNote)).toHaveLength(2);
  });

  it('renders reply placeholder by default', () => {
    expect(findReplyPlaceholder().exists()).toBe(true);
  });

  it('hides reply placeholder and opens form on placeholder click', () => {
    findReplyPlaceholder().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(findReplyPlaceholder().exists()).toBe(false);
      expect(findReplyForm().exists()).toBe(true);
    });
  });

  it('calls mutation on submitting form and closes the form', () => {
    wrapper.setData({
      discussionComment: 'test',
      isFormRendered: true,
    });

    return wrapper.vm
      .$nextTick()
      .then(() => {
        findReplyForm().vm.$emit('submitForm');

        expect(mutate).toHaveBeenCalledWith(mutationVariables);

        return mutate({ variables: mutationVariables });
      })
      .then(() => {
        expect(findReplyForm().exists()).toBe(false);
      });
  });

  it('clears the discussion comment on closing comment form', () => {
    wrapper.setData({
      discussionComment: 'test',
      isFormRendered: true,
    });

    return wrapper.vm
      .$nextTick()
      .then(() => {
        findReplyForm().vm.$emit('cancelForm');

        expect(wrapper.vm.discussionComment).toBe('');
        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(findReplyForm().exists()).toBe(false);
      });
  });
});
