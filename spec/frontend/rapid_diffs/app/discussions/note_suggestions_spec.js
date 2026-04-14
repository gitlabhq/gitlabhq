import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { defineStore } from 'pinia';
import NoteSuggestions from '~/rapid_diffs/app/discussions/note_suggestions.vue';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';

describe('NoteSuggestions', () => {
  let wrapper;
  let store;

  const useTestStore = defineStore('testMrDiscussions', () => {
    const batchSuggestionsInfo = ref([]);
    const suggestionsCount = ref(0);
    return {
      batchSuggestionsInfo,
      suggestionsCount,
      submitSuggestion: () => Promise.resolve(),
      submitSuggestionBatch: () => Promise.resolve(),
      addSuggestionInfoToBatch: () => {},
      removeSuggestionInfoFromBatch: () => {},
      suggestionsFilePaths: ref([]),
    };
  });

  const createNote = (overrides = {}) => ({
    id: '123',
    discussion_id: 'disc-1',
    note_html: '<p>suggestion content</p>',
    suggestions: [{ id: 1, appliable: true, applied: false }],
    position: { new_path: 'app/models/user.rb' },
    ...overrides,
  });

  const createComponent = (note = createNote()) => {
    wrapper = shallowMount(NoteSuggestions, {
      propsData: { note },
      provide: {
        store,
        suggestionsHelpPath: '/help/suggestions',
        defaultSuggestionCommitMessage: 'Apply %{suggestions_count} suggestion(s)',
      },
    });
  };

  const findSuggestions = () => wrapper.findComponent(Suggestions);

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useTestStore();
  });

  it('renders Suggestions with correct props', () => {
    store.suggestionsCount = 3;
    store.batchSuggestionsInfo = [{ suggestionId: 1 }];
    const note = createNote();
    createComponent(note);
    expect(findSuggestions().props()).toMatchObject({
      suggestions: note.suggestions,
      noteHtml: note.note_html,
      helpPagePath: '/help/suggestions',
      suggestionsCount: 3,
      batchSuggestionsInfo: [{ suggestionId: 1 }],
    });
  });

  it('computes commit message from template', () => {
    createComponent();
    expect(findSuggestions().props('defaultCommitMessage')).toBe('Apply 1 suggestion(s)');
  });

  it('calls store.submitSuggestion on apply', () => {
    createComponent();
    findSuggestions().vm.$emit('apply', {
      suggestionId: 1,
      flashContainer: document.body,
      message: 'msg',
    });
    expect(store.submitSuggestion).toHaveBeenCalledWith(
      expect.objectContaining({
        suggestionId: 1,
        discussionId: 'disc-1',
        noteId: '123',
        message: 'msg',
      }),
    );
  });

  it('calls store.submitSuggestionBatch on applyBatch', () => {
    createComponent();
    findSuggestions().vm.$emit('applyBatch', { message: 'batch msg' });
    expect(store.submitSuggestionBatch).toHaveBeenCalledWith({ message: 'batch msg' });
  });

  it('calls store.addSuggestionInfoToBatch on addToBatch', () => {
    createComponent();
    findSuggestions().vm.$emit('addToBatch', 42);
    expect(store.addSuggestionInfoToBatch).toHaveBeenCalledWith({
      suggestionId: 42,
      discussionId: 'disc-1',
      noteId: '123',
    });
  });

  it('calls store.removeSuggestionInfoFromBatch on removeFromBatch', () => {
    createComponent();
    findSuggestions().vm.$emit('removeFromBatch', 42);
    expect(store.removeSuggestionInfoFromBatch).toHaveBeenCalledWith(42);
  });
});
