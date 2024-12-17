import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import DiffDiscussionReply from '~/diffs/components/diff_discussion_reply.vue';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import DiscussionLockedWidget from '~/notes/components/discussion_locked_widget.vue';

import { START_THREAD } from '~/diffs/i18n';

Vue.use(Vuex);

describe('DiffDiscussionReply', () => {
  let wrapper;
  let getters;
  let store;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(DiffDiscussionReply, {
      store,
      propsData: {
        ...props,
      },
      slots: {
        ...slots,
      },
    });
  };

  describe('if user is signed in', () => {
    beforeEach(() => {
      getters = {
        userCanReply: () => true,
        getNoteableData: () => ({
          current_user: {
            can_create_note: true,
          },
        }),
        getUserData: () => ({
          path: 'test-path',
          avatar_url: 'avatar_url',
          name: 'John Doe',
          id: 1,
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

    it('should render a reply placeholder button if there is no form', () => {
      createComponent({
        renderReplyPlaceholder: true,
        hasForm: false,
      });

      expect(wrapper.findComponent(GlButton).text()).toBe(START_THREAD);
    });

    it.each`
      userCanReply | hasForm  | renderReplyPlaceholder | showButton
      ${false}     | ${false} | ${false}               | ${false}
      ${true}      | ${false} | ${false}               | ${false}
      ${true}      | ${true}  | ${false}               | ${false}
      ${true}      | ${true}  | ${true}                | ${false}
      ${true}      | ${false} | ${true}                | ${true}
      ${false}     | ${false} | ${true}                | ${false}
    `(
      'reply button existence is `$showButton` when userCanReply is `$userCanReply`, hasForm is `$hasForm` and renderReplyPlaceholder is `$renderReplyPlaceholder`',
      ({ userCanReply, hasForm, renderReplyPlaceholder, showButton }) => {
        getters = {
          ...getters,
          userCanReply: () => userCanReply,
        };

        store = new Vuex.Store({
          getters,
        });

        createComponent({
          renderReplyPlaceholder,
          hasForm,
        });

        expect(wrapper.findComponent(GlButton).exists()).toBe(showButton);
      },
    );

    it('shows the locked discussion widget when the user is not allowed to create notes', () => {
      getters = {
        ...getters,
        getNoteableData: () => ({
          current_user: {
            can_create_note: false,
          },
        }),
      };

      store = new Vuex.Store({
        getters,
      });

      createComponent({
        renderReplyPlaceholder: false,
        hasForm: false,
      });

      expect(wrapper.findComponent(DiscussionLockedWidget).exists()).toBe(true);
    });
  });

  describe('if user is signed out', () => {
    beforeEach(() => {
      getters = {
        userCanReply: () => false,
        getNoteableData: () => ({
          current_user: {
            can_create_note: false,
          },
        }),
        getUserData: () => null,
      };

      store = new Vuex.Store({
        getters,
      });
    });

    it('renders a signed out widget when user is not logged in', () => {
      createComponent({
        renderReplyPlaceholder: false,
        hasForm: false,
      });

      expect(wrapper.findComponent(NoteSignedOutWidget).exists()).toBe(true);
    });
  });
});
