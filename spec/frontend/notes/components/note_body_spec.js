import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteBody from '~/notes/components/note_body.vue';
import NoteAwardsList from '~/notes/components/note_awards_list.vue';
import NoteForm from '~/notes/components/note_form.vue';
import createStore from '~/notes/stores';
import notes from '~/notes/stores/modules/index';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { noteableDataMock, notesDataMock, note } from '../mock_data';

jest.mock('~/autosave');

Vue.use(PiniaVuePlugin);

describe('issue_note_body component', () => {
  let wrapper;
  let pinia;

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

    wrapper = shallowMountExtended(NoteBody, {
      store: mockStore || store,
      pinia,
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

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useMrNotes();
    createComponent();
  });

  it('should render the note', () => {
    expect(wrapper.text()).toBe(note.note);
  });

  it('should render awards list', () => {
    expect(wrapper.findComponent(NoteAwardsList).exists()).toBe(true);
  });

  describe('isInternalNote', () => {
    beforeEach(() => {
      createComponent({ props: { isInternalNote: true } });
    });
  });

  describe('isEditing', () => {
    const autosaveKey = 'autosave';

    beforeEach(() => {
      createComponent({
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
      createComponent({ props: { note: { ...note, internal }, isEditing: true } });

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
      const mrMetadata = {
        branch_name: 'branch',
        project_path: '/path',
        project_name: 'name',
        username: 'user',
        user_full_name: 'user userton',
      };
      const notesStore = notes();

      notesStore.state.notes = {};

      const store = new Vuex.Store({
        modules: {
          notes: notesStore,
          page: {
            namespaced: true,
            state: {
              mrMetadata,
            },
          },
        },
      });

      useMrNotes().mrMetadata = mrMetadata;
      useLegacyDiffs().defaultSuggestionCommitMessage =
        '*** %{branch_name} %{project_path} %{project_name} %{username} %{user_full_name} %{file_paths} %{suggestions_count} %{files_count} %{co_authored_by}';

      createComponent({
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
        createComponent({
          props: { note: { ...note, type, author: { ...note.author, user_type: userType } } },
        });

        expect(wrapper.findByTestId('code-review-feedback').exists()).toBe(exists);
      },
    );
  });

  describe('duo code review feedback text', () => {
    const createMockStoreWithDiscussion = (discussionId, discussionNotes) => {
      return new Vuex.Store({
        getters: {
          getDiscussion: () => (id) => {
            if (id === discussionId) {
              return { notes: discussionNotes };
            }
            return {};
          },
          suggestionsCount: () => 0,
          getSuggestionsFilePaths: () => [],
        },
        modules: {
          notes: {
            state: { batchSuggestionsInfo: [] },
          },
          page: {
            state: { failedToLoadMetadata: false },
          },
        },
      });
    };

    const createDuoNote = (props = {}) => ({
      ...note,
      id: '1',
      type: 'DiffNote',
      discussion_id: 'discussion1',
      author: {
        ...note.author,
        user_type: 'duo_code_review_bot',
      },
      ...props,
    });

    it('renders feedback text for the first DiffNote from GitLabDuo', () => {
      const duoNote = createDuoNote();
      const mockStore = createMockStoreWithDiscussion('discussion1', [duoNote]);

      createComponent({
        props: { note: duoNote },
        store: mockStore,
      });

      const feedbackDiv = wrapper.find('.gl-text-md.gl-mt-4.gl-text-gray-500');
      expect(feedbackDiv.exists()).toBe(true);
    });

    it('does not render feedback text for non-DiffNote from GitLabDuo', () => {
      const duoNote = createDuoNote({ type: 'DiscussionNote' });

      createComponent({
        props: { note: duoNote },
      });

      const feedbackDiv = wrapper.find('.gl-text-md.gl-mt-4.gl-text-gray-500');
      expect(feedbackDiv.exists()).toBe(false);
    });

    it('does not render feedback text for follow-up DiffNote from GitLabDuo', () => {
      const duoNote = createDuoNote({ id: '2' });
      const mockStore = createMockStoreWithDiscussion('discussion1', [
        { id: '1' }, // First note has different ID
        duoNote,
      ]);

      createComponent({
        props: { note: duoNote },
        store: mockStore,
      });

      const feedbackDiv = wrapper.find('.gl-text-md.gl-mt-4.gl-text-gray-500');
      expect(feedbackDiv.exists()).toBe(false);
    });

    it('shows default awards list with thumbsup and thumbsdown for first DiffNote from GitLabDuo', () => {
      const duoNote = createDuoNote();
      const mockStore = createMockStoreWithDiscussion('discussion1', [duoNote]);

      createComponent({
        props: { note: duoNote },
        store: mockStore,
      });

      const awardsList = wrapper.findComponent(NoteAwardsList);
      expect(awardsList.exists()).toBe(true);
      expect(awardsList.props('defaultAwards')).toEqual(['thumbsup', 'thumbsdown']);
    });

    it('uses empty default awards list for non-Duo comments', () => {
      const regularNote = {
        ...note,
        id: '1',
        author: {
          ...note.author,
          user_type: 'human',
        },
      };

      createComponent({
        props: { note: regularNote },
      });

      const awardsList = wrapper.findComponent(NoteAwardsList);
      expect(awardsList.props('defaultAwards')).toEqual([]);
    });

    describe('duoFeedbackText computed property', () => {
      it('returns the expected feedback text', () => {
        createComponent();

        const result = wrapper.vm.duoFeedbackText;
        expect(result).toContain('Rate this response');
        expect(result).toContain('@GitLabDuo');
        expect(result).toContain('in reply for more questions');
      });
    });
  });
});
