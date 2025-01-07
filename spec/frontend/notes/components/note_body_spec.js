// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { suggestionCommitMessage } from '~/diffs/store/getters';
import NoteBody from '~/notes/components/note_body.vue';
import NoteAwardsList from '~/notes/components/note_awards_list.vue';
import NoteForm from '~/notes/components/note_form.vue';
import createStore from '~/notes/stores';
import notes from '~/notes/stores/modules/index';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';
import { noteableDataMock, notesDataMock, note } from '../mock_data';

jest.mock('~/autosave');

const createComponent = ({
  props = {},
  noteableData = noteableDataMock,
  notesData = notesDataMock,
  store = null,
} = {}) => {
  let mockStore;

  if (!store) {
    mockStore = createStore();

    mockStore.dispatch('setNoteableData', noteableData);
    mockStore.dispatch('setNotesData', notesData);
  }

  return shallowMountExtended(NoteBody, {
    store: mockStore || store,
    propsData: {
      note,
      canEdit: true,
      canAwardEmoji: true,
      isEditing: false,
      ...props,
    },
    stubs: {
      DuoCodeReviewFeedback: true,
    },
  });
};

describe('issue_note_body component', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('should render the note', () => {
    expect(wrapper.text()).toBe(note.note);
  });

  it('should render awards list', () => {
    expect(wrapper.findComponent(NoteAwardsList).exists()).toBe(true);
  });

  describe('isInternalNote', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { isInternalNote: true } });
    });
  });

  describe('isEditing', () => {
    const autosaveKey = 'autosave';

    beforeEach(() => {
      wrapper = createComponent({
        props: { isEditing: true, autosaveKey, restoreFromAutosave: true },
      });
    });

    it('renders edit form', () => {
      expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
      expect(wrapper.findComponent(NoteForm).props('autosaveKey')).toBe(autosaveKey);
      expect(wrapper.findComponent(NoteForm).props('autosaveKey')).toBe(autosaveKey);
      expect(wrapper.findComponent(NoteForm).props('restoreFromAutosave')).toBe(true);
    });

    it.each`
      internal | buttonText
      ${false} | ${'Save comment'}
      ${true}  | ${'Save internal note'}
    `('renders save button with text "$buttonText"', ({ internal, buttonText }) => {
      wrapper = createComponent({ props: { note: { ...note, internal }, isEditing: true } });

      expect(wrapper.findComponent(NoteForm).props('saveButtonTitle')).toBe(buttonText);
    });

    describe('isInternalNote', () => {
      beforeEach(() => {
        wrapper.setProps({ isInternalNote: true });
      });
    });
  });

  describe('commitMessage', () => {
    beforeEach(() => {
      const notesStore = notes();

      notesStore.state.notes = {};

      const store = new Vuex.Store({
        modules: {
          notes: notesStore,
          diffs: {
            namespaced: true,
            state: {
              defaultSuggestionCommitMessage:
                '*** %{branch_name} %{project_path} %{project_name} %{username} %{user_full_name} %{file_paths} %{suggestions_count} %{files_count} %{co_authored_by}',
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

      wrapper = createComponent({
        store,
        props: {
          note: { ...note, suggestions: [12345] },
          canEdit: true,
          file: { file_path: 'abc' },
        },
      });
    });

    it('passes the correct default placeholder commit message for a suggestion to the suggestions component', () => {
      const commitMessage = wrapper.findComponent(Suggestions).attributes('defaultcommitmessage');

      expect(commitMessage).toBe(
        '*** branch /path name user user userton abc 1 1 Co-authored-by: ...',
      );
    });
  });

  describe('duo code review feedback', () => {
    it.each`
      userType                 | type                | exists   | existsText
      ${'duo_code_review_bot'} | ${null}             | ${true}  | ${'renders'}
      ${'duo_code_review_bot'} | ${'DiscussionNote'} | ${true}  | ${'renders'}
      ${'duo_code_review_bot'} | ${'DiffNote'}       | ${false} | ${'does not render'}
      ${'human'}               | ${null}             | ${false} | ${'does not render'}
    `(
      '$existsText code review feedback component when author type is "$userType" and note type is "$type"',
      ({ userType, type, exists }) => {
        wrapper = createComponent({
          props: { note: { ...note, type, author: { ...note.author, user_type: userType } } },
        });

        expect(wrapper.findByTestId('code-review-feedback').exists()).toBe(exists);
      },
    );
  });
});
