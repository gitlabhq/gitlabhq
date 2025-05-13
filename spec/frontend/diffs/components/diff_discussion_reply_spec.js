import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import DiffDiscussionReply from '~/diffs/components/diff_discussion_reply.vue';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import DiscussionLockedWidget from '~/notes/components/discussion_locked_widget.vue';
import { START_THREAD } from '~/diffs/i18n';
import { useNotes } from '~/notes/store/legacy_notes';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';

Vue.use(PiniaVuePlugin);

describe('DiffDiscussionReply', () => {
  let wrapper;
  let pinia;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(DiffDiscussionReply, {
      pinia,
      propsData: {
        ...props,
      },
      slots: {
        ...slots,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  describe('if user is signed in', () => {
    beforeEach(() => {
      useNotes().noteableData.current_user = { can_create_note: true };
      useNotes().userData = {
        path: 'test-path',
        avatar_url: 'avatar_url',
        name: 'John Doe',
        id: 1,
      };
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
        useNotes().noteableData.current_user = { can_create_note: userCanReply };

        createComponent({
          renderReplyPlaceholder,
          hasForm,
        });

        expect(wrapper.findComponent(GlButton).exists()).toBe(showButton);
      },
    );

    it('shows the locked discussion widget when the user is not allowed to create notes', () => {
      useNotes().noteableData.current_user = { can_create_note: false };

      createComponent({
        renderReplyPlaceholder: false,
        hasForm: false,
      });

      expect(wrapper.findComponent(DiscussionLockedWidget).exists()).toBe(true);
    });
  });

  describe('if user is signed out', () => {
    beforeEach(() => {
      useNotes().noteableData.current_user = { can_create_note: false };
      useNotes().userData = null;
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
