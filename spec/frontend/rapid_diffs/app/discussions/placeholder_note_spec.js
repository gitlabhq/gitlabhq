import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PlaceholderNote from '~/rapid_diffs/app/discussions/placeholder_note.vue';
import NoteHeader from '~/rapid_diffs/app/discussions/note_header.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(PiniaVuePlugin);

describe('PlaceholderNote', () => {
  let pinia;
  let wrapper;

  const userData = {
    id: 1,
    name: 'Root',
    username: 'root',
    avatar_url: '/avatar.png',
    path: '/root',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PlaceholderNote, {
      pinia,
      propsData: {
        note: { body: 'a **wip** note' },
        ...props,
      },
    });
  };

  const findHeader = () => wrapper.findComponent(NoteHeader);
  const findBody = () => wrapper.findByTestId('placeholder-note').find('.note-text');

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes().userData = userData;
  });

  it('passes the current user from the store to the header', () => {
    createComponent();
    expect(findHeader().props('author')).toStrictEqual(userData);
  });

  it('renders the note body', () => {
    createComponent({ note: { body: 'hello' } });
    expect(findBody().text()).toContain('hello');
  });
});
