import { shallowMount } from '@vue/test-utils';
import NoteSignedOutWidget from '~/notes/components/note_signed_out_widget.vue';
import createStore from '~/notes/stores';
import { notesDataMock } from '../mock_data';

describe('NoteSignedOutWidget component', () => {
  let wrapper;

  beforeEach(() => {
    const store = createStore();
    store.dispatch('setNotesData', notesDataMock);
    wrapper = shallowMount(NoteSignedOutWidget, { store });
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
