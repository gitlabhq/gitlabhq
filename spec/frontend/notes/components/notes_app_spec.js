import { mount, shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import AxiosMockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { PiniaVuePlugin } from 'pinia';
import VueApollo from 'vue-apollo';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getLocationHash } from '~/lib/utils/url_utility';
import * as urlUtility from '~/lib/utils/url_utility';
import notesEventHub from '~/notes/event_hub';
import CommentForm from '~/notes/components/comment_form.vue';
import NotesApp from '~/notes/components/notes_app.vue';
import NotesActivityHeader from '~/notes/components/notes_activity_header.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import * as constants from '~/notes/constants';
import store from '~/mr_notes/stores';
import OrderedLayout from '~/notes/components/ordered_layout.vue';
// TODO: use generated fixture (https://gitlab.com/gitlab-org/gitlab-foss/issues/62491)
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { Mousetrap } from '~/lib/mousetrap';
import { ISSUABLE_COMMENT_OR_REPLY, keysFor } from '~/behaviors/shortcuts/keybindings';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import { useNotes } from '~/notes/store/legacy_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin, syncWithVuex } from '~/pinia/plugins';
import createMockApollo from 'helpers/mock_apollo_helper';
import noteQuery from '~/notes/graphql/note.query.graphql';
import { useBatchComments } from '~/batch_comments/store';
import * as types from '~/notes/stores/mutation_types';
import { SET_BATCH_COMMENTS_DRAFTS } from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import * as mockData from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/lib/utils/resize_observer', () => ({
  scrollToTargetOnResize: jest.fn(),
}));

const TYPE_COMMENT_FORM = 'comment-form';
const TYPE_NOTES_LIST = 'notes-list';
const TEST_NOTES_FILTER_VALUE = 1;

const propsData = {
  noteableData: mockData.noteableDataMock,
  notesData: mockData.notesDataMock,
  notesFilters: mockData.notesFilters,
  notesFilterValue: TEST_NOTES_FILTER_VALUE,
};

Vue.use(Vuex);
Vue.use(VueApollo);
Vue.use(PiniaVuePlugin);

describe('note_app', () => {
  let axiosMock;
  let wrapper;
  let pinia;

  const initStore = (notesData = propsData.notesData) => {
    store.dispatch('setNotesData', notesData);
    store.dispatch('setNoteableData', propsData.noteableData);
    store.dispatch('setUserData', mockData.userDataMock);
    store.dispatch('setTargetNoteHash', getLocationHash());
    // call after mounted hook
    queueMicrotask(() => {
      queueMicrotask(() => {
        store.dispatch('fetchNotes');
      });
    });
  };

  const mountComponent = ({ props = {} } = {}) => {
    initStore();
    wrapper = mount(
      {
        components: {
          NotesApp,
        },
        template: `<div class="js-vue-notes-event">
            <notes-app ref="notesApp" v-bind="$attrs" />
          </div>`,
        inheritAttrs: false,
      },
      {
        propsData: {
          ...propsData,
          ...props,
        },
        store,
        pinia,
      },
    );
  };

  const findCommentButton = () => wrapper.find('[data-testid="comment-button"]');

  const getComponentOrder = () => {
    const nodes = wrapper.findAll('#notes-list,.js-comment-form');
    const wrappers = nodes.wrappers || nodes; // Vue 2: use wrappers; Vue 3: nodes is the array

    return wrappers.map((node) =>
      node.findComponent(CommentForm).exists() ? TYPE_COMMENT_FORM : TYPE_NOTES_LIST,
    );
  };

  beforeEach(() => {
    store.commit('reset');
    $('body').attr('data-page', 'projects:merge_requests:show');

    axiosMock = new AxiosMockAdapter(axios);

    pinia = createTestingPinia({
      plugins: [globalAccessorPlugin, syncWithVuex],
      stubActions: false,
    });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('render', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      mountComponent();
      return waitForPromises();
    });

    it('should render list of notes', () => {
      const note =
        mockData.INDIVIDUAL_NOTE_RESPONSE_MAP.GET[
          '/gitlab-org/gitlab-foss/issues/26/discussions.json'
        ][0].notes[0];

      expect(wrapper.find('.main-notes-list .note-header-author-name').text().trim()).toEqual(
        note.author.name,
      );

      expect(wrapper.find('.main-notes-list .note-text').html()).toContain(note.note_html);
    });

    it('should render form', () => {
      expect(wrapper.find('.js-main-target-form').element.tagName).toBe('FORM');
      expect(wrapper.find('.js-main-target-form textarea').attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });

    // quarantine: https://gitlab.com/gitlab-org/gitlab/-/issues/410409
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('should render form comment button as disabled', () => {
      expect(findCommentButton().props('disabled')).toEqual(true);
    });

    it('should render notes activity header', () => {
      expect(wrapper.findComponent(NotesActivityHeader).props().notesFilterValue).toEqual(
        TEST_NOTES_FILTER_VALUE,
      );
      expect(wrapper.findComponent(NotesActivityHeader).props().notesFilters).toEqual(
        mockData.notesFilters,
      );
    });
  });

  describe('render with comments disabled', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      mountComponent({
        // why: In this integration test, previously we manually set store.state.commentsDisabled
        //      This stopped working when we added `<discussion-filter>` into the component tree.
        //      Let's lean into the integration scope and use a prop that "disables comments".
        props: {
          notesFilterValue: constants.HISTORY_ONLY_FILTER_VALUE,
        },
      });

      return waitForPromises();
    });

    it('should not render form when commenting is disabled', () => {
      expect(wrapper.find('.js-main-target-form').exists()).toBe(false);
    });

    it('should render discussion filter note `commentsDisabled` is true', () => {
      expect(wrapper.find('.js-discussion-filter-note').exists()).toBe(true);
    });
  });

  describe('timeline view', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      store.commit(types.SET_TIMELINE_VIEW, true);

      mountComponent();
      return waitForPromises();
    });

    it('should not render comments form', () => {
      expect(wrapper.find('.js-main-target-form').exists()).toBe(false);
    });
  });

  describe('while fetching data', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders skeleton notes', () => {
      expect(wrapper.find('.gl-skeleton-loader-default-container').exists()).toBe(true);
    });

    it('should render form', () => {
      expect(wrapper.find('.js-main-target-form').element.tagName).toBe('FORM');
      expect(wrapper.find('.js-main-target-form textarea').attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });
  });

  describe('update note', () => {
    describe('individual note', () => {
      beforeEach(() => {
        axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
        mountComponent();
        return waitForPromises().then(() => {
          wrapper.find('.js-note-edit').trigger('click');
        });
      });

      it('renders edit form', () => {
        expect(wrapper.find('.js-vue-issue-note-form').exists()).toBe(true);
      });

      it('calls the store action to update the note', async () => {
        jest.spyOn(axios, 'put').mockImplementation(() => Promise.resolve({ data: {} }));
        wrapper.find('.js-vue-issue-note-form').value = 'this is a note';
        wrapper.find('.js-vue-issue-save').trigger('click');
        await waitForPromises();

        expect(axios.put).toHaveBeenCalled();
      });
    });

    describe('discussion note', () => {
      beforeEach(() => {
        axiosMock.onAny().reply(mockData.getDiscussionNoteResponse);
        mountComponent();
        return waitForPromises().then(() => {
          wrapper.find('.js-note-edit').trigger('click');
        });
      });

      it('renders edit form', () => {
        expect(wrapper.find('.js-vue-issue-note-form').exists()).toBe(true);
      });

      it('updates the note and resets the edit form', async () => {
        jest.spyOn(axios, 'put').mockImplementation(() => Promise.resolve({ data: {} }));
        wrapper.find('.js-vue-issue-note-form').value = 'this is a note';
        wrapper.find('.js-vue-issue-save').trigger('click');
        await waitForPromises();

        expect(axios.put).toHaveBeenCalled();
      });
    });
  });

  describe('new note form', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      mountComponent();
      return waitForPromises();
    });

    it('should render markdown docs url', () => {
      const { markdownDocsPath } = mockData.notesDataMock;

      expect(wrapper.find(`a[href="${markdownDocsPath}"]`).exists()).toBe(true);
    });
  });

  describe('edit form', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      mountComponent();
      return waitForPromises();
    });

    it('should render markdown docs url', async () => {
      wrapper.find('.js-note-edit').trigger('click');
      const { markdownDocsPath } = mockData.notesDataMock;

      await nextTick();
      expect(wrapper.find(`.edit-note a[href="${markdownDocsPath}"]`).exists()).toBe(true);
    });
  });

  describe('emoji awards', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, []);
      mountComponent();
      return waitForPromises();
    });

    it('dispatches toggleAward after toggleAward event', () => {
      const spy = jest.spyOn(store, 'dispatch').mockImplementation(jest.fn());
      const toggleAwardEvent = new CustomEvent('toggleAward', {
        detail: {
          awardName: 'test',
          noteId: 1,
        },
      });

      wrapper.element.dispatchEvent(toggleAwardEvent);

      jest.advanceTimersByTime(2);

      expect(spy).toHaveBeenCalledWith('toggleAward', {
        awardName: 'test',
        noteId: 1,
      });
      spy.mockRestore();
    });
  });

  describe('mounted', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      mountComponent();
      return waitForPromises();
    });

    it('should listen hashchange event for notes', () => {
      const hash = 'note_1234';
      jest.spyOn(urlUtility, 'getLocationHash').mockReturnValue(hash);
      const dispatchMock = jest.spyOn(store, 'dispatch');
      window.dispatchEvent(new Event('hashchange'), hash);

      expect(dispatchMock).toHaveBeenCalledWith('setTargetNoteHash', 'note_1234');
    });
  });

  describe('when sort direction is desc', () => {
    beforeEach(() => {
      store.commit(types.SET_DISCUSSIONS_SORT, { direction: constants.DESC });
      store.commit(types.SET_NOTES_LOADING_STATE, true);
      store.commit(types.ADD_NEW_NOTE, { discussion: mockData.discussionMock });

      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
        pinia,
        stubs: {
          'ordered-layout': OrderedLayout,
        },
      });
    });

    it('finds CommentForm before notes list', () => {
      expect(getComponentOrder()).toStrictEqual([TYPE_COMMENT_FORM, TYPE_NOTES_LIST]);
    });

    it('shows skeleton notes before the loaded discussions', () => {
      expect(wrapper.find('#notes-list').html()).toMatchSnapshot();
    });
  });

  describe('when sort direction is asc', () => {
    beforeEach(() => {
      store.commit(types.SET_NOTES_LOADING_STATE, true);
      store.commit(types.ADD_NEW_NOTE, { discussion: mockData.discussionMock });

      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
        pinia,
        stubs: {
          'ordered-layout': OrderedLayout,
        },
      });
    });

    it('finds CommentForm after notes list', () => {
      expect(getComponentOrder()).toStrictEqual([TYPE_NOTES_LIST, TYPE_COMMENT_FORM]);
    });

    it('shows skeleton notes after the loaded discussions', () => {
      expect(wrapper.find('#notes-list').html()).toMatchSnapshot();
    });
  });

  describe('preview note', () => {
    let noteQueryHandler;

    function hashFactory({ urlHash, authorId } = {}) {
      jest.spyOn(urlUtility, 'getLocationHash').mockReturnValue(urlHash);

      noteQueryHandler = jest
        .fn()
        .mockResolvedValue(mockData.singleNoteResponseFactory({ urlHash, authorId }));

      store.commit(types.SET_NOTES_LOADING_STATE, true);
      store.commit(types.SET_TARGET_NOTE_HASH, urlHash);

      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
        pinia,
        apolloProvider: createMockApollo([[noteQuery, noteQueryHandler]]),
        stubs: {
          'ordered-layout': OrderedLayout,
        },
      });
    }

    it('calls query when note id exists', async () => {
      hashFactory({ urlHash: 'note_123' });

      expect(noteQueryHandler).toHaveBeenCalled();
      await waitForPromises();

      expect(wrapper.findComponent(NoteableDiscussion).exists()).toBe(true);
    });

    it('converts all ids from graphql to numeric', async () => {
      hashFactory({ urlHash: 'note_1234', authorId: 5 });

      await waitForPromises();

      const note = wrapper.findComponent(NoteableDiscussion).props('discussion').notes[0];

      expect(note.id).toBe('1234');
      expect(note.author.id).toBe(5);
    });

    it('does not call query when note id does not exist', () => {
      hashFactory();

      expect(noteQueryHandler).not.toHaveBeenCalled();
    });

    it('does not call query when url hash is not a note', () => {
      hashFactory({ urlHash: 'not_123' });

      expect(noteQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when multiple draft types are present', () => {
    beforeEach(() => {
      store.commit(types.SET_NOTES_LOADING_STATE, true);
      store.commit(`batchComments/${SET_BATCH_COMMENTS_DRAFTS}`, [
        mockData.draftDiffDiscussion,
        mockData.draftReply,
        ...mockData.draftComments,
      ]);
      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
        pinia,
        stubs: {
          OrderedLayout,
        },
      });
    });

    afterEach(() => {
      store.commit('batchComments/reset');
    });

    it('correctly finds only draft comments', () => {
      const drafts = wrapper.findAllComponents(DraftNote).wrappers;

      expect(drafts.map((x) => x.props('draft'))).toEqual(
        mockData.draftComments.map(({ note }) => expect.objectContaining({ note })),
      );
    });
  });

  describe('fetching discussions', () => {
    describe('when note anchor is not present', () => {
      it('does not include extra query params', async () => {
        initStore();
        wrapper = shallowMount(NotesApp, { propsData, store, pinia });
        await waitForPromises();

        expect(axiosMock.history.get[0].params).toEqual({ per_page: 20 });
      });
    });

    describe('when note anchor is present', () => {
      const mountWithNotesFilter = (notesFilter) => {
        initStore({
          ...propsData.notesData,
          notesFilter,
        });
        return shallowMount(NotesApp, {
          propsData,
          store,
          pinia,
        });
      };

      beforeEach(() => {
        setWindowLocation('#note_1');
      });

      it('does not include extra query params when filter is undefined', async () => {
        wrapper = mountWithNotesFilter(undefined);
        await waitForPromises();

        expect(axiosMock.history.get[0].params).toEqual({ per_page: 20 });
      });

      it('does not include extra query params when filter is already set to default', async () => {
        wrapper = mountWithNotesFilter(constants.DISCUSSION_FILTERS_DEFAULT_VALUE);
        await waitForPromises();

        expect(axiosMock.history.get[0].params).toEqual({ per_page: 20 });
      });

      it('includes extra query params when filter is not set to default', async () => {
        wrapper = mountWithNotesFilter(constants.COMMENTS_ONLY_FILTER_VALUE);
        await waitForPromises();

        expect(axiosMock.history.get[0].params).toEqual({
          notes_filter: constants.DISCUSSION_FILTERS_DEFAULT_VALUE,
          per_page: 20,
          persist_filter: false,
        });
      });
    });
  });

  describe('draft comments', () => {
    let trackingSpy;

    beforeEach(() => {
      window.mrTabs = { eventHub: notesEventHub };
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
      mountComponent();
    });

    describe('when adding a new comment to an existing review', () => {
      it('sends the correct tracking event', () => {
        notesEventHub.$emit('noteFormAddToReview', { name: 'noteFormAddToReview' });

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'merge_request_click_add_to_review_on_overview_tab',
          expect.any(Object),
        );
      });
    });

    describe('when adding a comment to a new review', () => {
      it('sends the correct tracking event', () => {
        notesEventHub.$emit('noteFormStartReview', { name: 'noteFormStartReview' });

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'merge_request_click_start_review_on_overview_tab',
          expect.any(Object),
        );
      });
    });
  });

  describe('reply hotkey', () => {
    useFakeRequestAnimationFrame();

    const stubSelection = (startContainer) => {
      window.getSelection = () => ({
        rangeCount: 1,
        getRangeAt: () => ({ startContainer }),
      });
    };

    it('sends quote to main reply editor', async () => {
      jest.spyOn(CopyAsGFM, 'selectionToGfm').mockReturnValueOnce('foo');
      mountComponent();
      const replySpy = jest.spyOn(wrapper.findComponent(CommentForm).vm, 'append');
      const target = wrapper.element.querySelector('p');
      stubSelection(target);
      Mousetrap.trigger(keysFor(ISSUABLE_COMMENT_OR_REPLY)[0]);
      await nextTick();
      expect(replySpy).toHaveBeenCalledWith('foo');
    });

    it('sends quote to discussion reply editor', async () => {
      jest.spyOn(CopyAsGFM, 'selectionToGfm').mockReturnValueOnce('foo');
      axiosMock.onAny().reply(mockData.getDiscussionNoteResponse);
      mountComponent();
      await waitForPromises();
      const replySpy = jest.spyOn(wrapper.findComponent(NoteableDiscussion).vm, 'showReplyForm');
      const target = wrapper.element.querySelector('.js-noteable-discussion p');
      stubSelection(target);
      Mousetrap.trigger(keysFor(ISSUABLE_COMMENT_OR_REPLY)[0]);
      await nextTick();
      expect(replySpy).toHaveBeenCalledWith('foo');
    });
  });

  describe('noteableType computed property', () => {
    const createComponent = (noteableType, type) => {
      return shallowMount(NotesApp, {
        propsData: {
          ...propsData,
          noteableData: {
            ...propsData.noteableData,
            noteableType,
            type,
          },
        },
        store,
        pinia,
      });
    };

    it('returns the noteableType as is for regular types', () => {
      wrapper = createComponent('Issue', 'issue');
      expect(wrapper.findComponent(NotesActivityHeader).props('noteableType')).toBe('Issue');

      wrapper = createComponent('MergeRequest', 'merge_request');
      expect(wrapper.findComponent(NotesActivityHeader).props('noteableType')).toBe('MergeRequest');
    });

    it('capitalizes the first letter for incident type & does not return noteableType', () => {
      wrapper = createComponent('Incident', 'incident');
      expect(wrapper.findComponent(NotesActivityHeader).props('noteableType')).toBe('Incident');

      wrapper = createComponent('Issue', 'incident');
      expect(wrapper.findComponent(NotesActivityHeader).props('noteableType')).toBe('Incident');
    });

    it('handles empty values gracefully', () => {
      wrapper = createComponent('', '');
      expect(wrapper.findComponent(NotesActivityHeader).props('noteableType')).toBe('');
      expect(wrapper.vm.noteableType).toBe('');
    });
  });
});
