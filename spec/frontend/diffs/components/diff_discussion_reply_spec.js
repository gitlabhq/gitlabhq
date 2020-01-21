import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffDiscussionReply from '~/diffs/components/diff_discussion_reply.vue';
import ReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DiffDiscussionReply', () => {
  let wrapper;
  let getters;
  let store;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(DiffDiscussionReply, {
      store,
      localVue,
      propsData: {
        ...props,
      },
      slots: {
        ...slots,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('if user can reply', () => {
    beforeEach(() => {
      getters = {
        userCanReply: () => true,
        getUserData: () => ({
          path: 'test-path',
          avatar_url: 'avatar_url',
          name: 'John Doe',
        }),
      };

      store = new Vuex.Store({
        getters,
      });
    });

    it('should render a form if component has form', () => {
      createComponent(
        {
          renderReplyPlaceholder: false,
          hasForm: true,
        },
        {
          form: `<div id="test-form"></div>`,
        },
      );

      expect(wrapper.find('#test-form').exists()).toBe(true);
    });

    it('should render a reply placeholder if there is no form', () => {
      createComponent({
        renderReplyPlaceholder: true,
        hasForm: false,
      });

      expect(wrapper.find(ReplyPlaceholder).exists()).toBe(true);
    });
  });

  it('renders a signed out widget when user is not logged in', () => {
    getters = {
      userCanReply: () => false,
      getUserData: () => null,
    };

    store = new Vuex.Store({
      getters,
    });

    createComponent({
      renderReplyPlaceholder: false,
      hasForm: false,
    });

    expect(wrapper.find(NoteSignedOutWidget).exists()).toBe(true);
  });
});
