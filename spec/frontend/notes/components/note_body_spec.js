import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import { suggestionCommitMessage } from '~/diffs/store/getters';
import noteBody from '~/notes/components/note_body.vue';
import createStore from '~/notes/stores';
import notes from '~/notes/stores/modules/index';

import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';

import { noteableDataMock, notesDataMock, note } from '../mock_data';

describe('issue_note_body component', () => {
  let store;
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(noteBody);

    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
      propsData: {
        note,
        canEdit: true,
        canAwardEmoji: true,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render the note', () => {
    expect(vm.$el.querySelector('.note-text').innerHTML).toEqual(note.note_html);
  });

  it('should render awards list', () => {
    expect(vm.$el.querySelector('.js-awards-block button [data-name="baseball"]')).not.toBeNull();
    expect(vm.$el.querySelector('.js-awards-block button [data-name="bath_tone3"]')).not.toBeNull();
  });

  describe('isEditing', () => {
    beforeEach((done) => {
      vm.isEditing = true;
      Vue.nextTick(done);
    });

    it('renders edit form', () => {
      expect(vm.$el.querySelector('textarea.js-task-list-field')).not.toBeNull();
    });

    it('adds autosave', () => {
      const autosaveKey = `autosave/Note/${note.noteable_type}/${note.id}`;

      expect(vm.autosave).toExist();
      expect(vm.autosave.key).toEqual(autosaveKey);
    });
  });

  describe('commitMessage', () => {
    let wrapper;

    Vue.use(Vuex);

    beforeEach(() => {
      const notesStore = notes();

      notesStore.state.notes = {};

      store = new Vuex.Store({
        modules: {
          notes: notesStore,
          diffs: {
            namespaced: true,
            state: {
              defaultSuggestionCommitMessage:
                '%{branch_name}%{project_path}%{project_name}%{username}%{user_full_name}%{file_paths}%{suggestions_count}%{files_count}',
            },
            getters: { suggestionCommitMessage },
          },
          page: {
            namespaced: true,
            state: {
              mrMetadata: {
                branch_name: 'branch',
                project_path: '/path',
                project_name: 'name',
                username: 'user',
                user_full_name: 'user userton',
              },
            },
          },
        },
      });

      wrapper = shallowMount(noteBody, {
        store,
        propsData: {
          note: { ...note, suggestions: [12345] },
          canEdit: true,
          file: { file_path: 'abc' },
        },
      });
    });

    it('passes the correct default placeholder commit message for a suggestion to the suggestions component', () => {
      const commitMessage = wrapper.find(Suggestions).attributes('defaultcommitmessage');

      expect(commitMessage).toBe('branch/pathnameuseruser usertonabc11');
    });
  });
});
