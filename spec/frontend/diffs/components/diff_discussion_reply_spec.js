import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import DiffDiscussionReply from '~/diffs/components/diff_discussion_reply.vue';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import DiscussionLockedWidget from '~/notes/components/discussion_locked_widget.vue';
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
        renderReplyPlaceholder: true,
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

  describe('when user is signed out', () => {
    beforeEach(() => {
      useNotes().noteableData.current_user = { can_create_note: false };
      useNotes().userData = null;
    });

    it('shows signed out widget', () => {
      createComponent({ renderReplyPlaceholder: false });

      expect(wrapper.findComponent(NoteSignedOutWidget).exists()).toBe(true);
      expect(wrapper.findComponent(DiscussionLockedWidget).exists()).toBe(false);
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });

  describe('when user is signed in but cannot reply', () => {
    beforeEach(() => {
      useNotes().noteableData.current_user = { can_create_note: false };
      useNotes().userData = {
        path: 'test-path',
        avatar_url: 'avatar_url',
        name: 'John Doe',
        id: 1,
      };
    });

    it('shows locked discussion widget', () => {
      createComponent({ renderReplyPlaceholder: false });

      expect(wrapper.findComponent(DiscussionLockedWidget).exists()).toBe(true);
      expect(wrapper.findComponent(NoteSignedOutWidget).exists()).toBe(false);
      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });
  });

  describe('when user can reply', () => {
    beforeEach(() => {
      useNotes().noteableData.current_user = { can_create_note: true };
      useNotes().userData = {
        path: 'test-path',
        avatar_url: 'avatar_url',
        name: 'John Doe',
        id: 1,
      };
    });

    describe.each`
      renderReplyPlaceholder | slot                                      | placeholderVisible | formVisible
      ${true}                | ${{ form: '<div id="test-form"></div>' }} | ${false}           | ${true}
      ${true}                | ${{}}                                     | ${true}            | ${false}
      ${false}               | ${{ form: '<div id="test-form"></div>' }} | ${false}           | ${true}
      ${false}               | ${{}}                                     | ${false}           | ${false}
    `(
      'when renderReplyPlaceholder=$renderReplyPlaceholder and slot=$slot',
      ({ renderReplyPlaceholder, slot, placeholderVisible, formVisible }) => {
        it(`renders correctly`, () => {
          createComponent({ renderReplyPlaceholder }, slot);

          expect(wrapper.findComponent(GlButton).exists()).toBe(placeholderVisible);
          expect(wrapper.find('#test-form').exists()).toBe(formVisible);
        });
      },
    );

    it('emits showNewDiscussionForm when button is clicked', () => {
      createComponent({ renderReplyPlaceholder: true });

      wrapper.findComponent(GlButton).vm.$emit('click');

      expect(wrapper.emitted('showNewDiscussionForm')).toHaveLength(1);
    });
  });
});
