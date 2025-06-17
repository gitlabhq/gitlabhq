import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { notesDataMock } from '../mock_data';

Vue.use(PiniaVuePlugin);

describe('NoteSignedOutWidget component', () => {
  let wrapper;
  let pinia;

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin], stubActions: false });
    useLegacyDiffs();
    useNotes().setNotesData(notesDataMock);
    wrapper = shallowMount(NoteSignedOutWidget, { pinia });
  });

  it('renders sign in link provided in the store', () => {
    expect(wrapper.find(`a[href="${notesDataMock.newSessionPath}"]`).text()).toBe('sign in');
  });

  it('renders register link provided in the store', () => {
    expect(wrapper.find(`a[href="${notesDataMock.registerPath}"]`).text()).toBe('register');
  });

  it('renders information text', () => {
    expect(wrapper.text()).toContain('Please register or sign in to reply');
  });
});
