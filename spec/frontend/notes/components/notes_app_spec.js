import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { nextTick } from 'vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getLocationHash } from '~/lib/utils/url_utility';
import * as urlUtility from '~/lib/utils/url_utility';
import notesEventHub from '~/notes/event_hub';
import CommentForm from '~/notes/components/comment_form.vue';
import NotesApp from '~/notes/components/notes_app.vue';
import NotesActivityHeader from '~/notes/components/notes_activity_header.vue';
import * as constants from '~/notes/constants';
import createStore from '~/notes/stores';
import OrderedLayout from '~/vue_shared/components/ordered_layout.vue';
// TODO: use generated fixture (https://gitlab.com/gitlab-org/gitlab-foss/issues/62491)
import * as mockData from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

const TYPE_COMMENT_FORM = 'comment-form';
const TYPE_NOTES_LIST = 'notes-list';
const TEST_NOTES_FILTER_VALUE = 1;

const propsData = {
  noteableData: mockData.noteableDataMock,
  notesData: mockData.notesDataMock,
  notesFilters: mockData.notesFilters,
  notesFilterValue: TEST_NOTES_FILTER_VALUE,
};

describe('note_app', () => {
  let axiosMock;
  let mountComponent;
  let wrapper;
  let store;

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

  const findCommentButton = () => wrapper.find('[data-testid="comment-button"]');

  const getComponentOrder = () => {
    return wrapper
      .findAll('#notes-list,.js-comment-form')
      .wrappers.map((node) => (node.is(CommentForm) ? TYPE_COMMENT_FORM : TYPE_NOTES_LIST));
  };

  beforeEach(() => {
    $('body').attr('data-page', 'projects:merge_requests:show');

    axiosMock = new AxiosMockAdapter(axios);

    store = createStore();

    mountComponent = ({ props = {} } = {}) => {
      initStore();
      return mount(
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
        },
      );
    };
  });

  afterEach(() => {
    axiosMock.restore();
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
  });

  describe('render', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      wrapper = mountComponent();
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
      wrapper = mountComponent({
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
      store.state.commentsDisabled = false;
      store.state.isTimelineEnabled = true;

      wrapper = mountComponent();
      return waitForPromises();
    });

    it('should not render comments form', () => {
      expect(wrapper.find('.js-main-target-form').exists()).toBe(false);
    });
  });

  describe('while fetching data', () => {
    beforeEach(() => {
      wrapper = mountComponent();
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
        wrapper = mountComponent();
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
        wrapper = mountComponent();
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
      wrapper = mountComponent();
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
      wrapper = mountComponent();
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
      wrapper = mountComponent();
      return waitForPromises();
    });

    it('dispatches toggleAward after toggleAward event', () => {
      const toggleAwardEvent = new CustomEvent('toggleAward', {
        detail: {
          awardName: 'test',
          noteId: 1,
        },
      });
      const toggleAwardAction = jest.fn().mockName('toggleAward');
      wrapper.vm.$store.hotUpdate({
        actions: {
          toggleAward: toggleAwardAction,
        },
      });

      wrapper.vm.$parent.$el.dispatchEvent(toggleAwardEvent);

      jest.advanceTimersByTime(2);

      expect(toggleAwardAction).toHaveBeenCalledTimes(1);
      const [, payload] = toggleAwardAction.mock.calls[0];

      expect(payload).toEqual({
        awardName: 'test',
        noteId: 1,
      });
    });
  });

  describe('mounted', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      wrapper = mountComponent();
      return waitForPromises();
    });

    it('should listen hashchange event', () => {
      const hash = 'some dummy hash';
      jest.spyOn(urlUtility, 'getLocationHash').mockReturnValue(hash);
      const dispatchMock = jest.spyOn(store, 'dispatch');
      window.dispatchEvent(new Event('hashchange'), hash);

      expect(dispatchMock).toHaveBeenCalledWith('setTargetNoteHash', 'some dummy hash');
    });
  });

  describe('when sort direction is desc', () => {
    beforeEach(() => {
      store = createStore();
      store.state.discussionSortOrder = constants.DESC;
      store.state.isLoading = true;
      store.state.discussions = [mockData.discussionMock];

      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
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
      store = createStore();
      store.state.isLoading = true;
      store.state.discussions = [mockData.discussionMock];

      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
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

  describe('when multiple draft types are present', () => {
    beforeEach(() => {
      store = createStore();
      store.registerModule('batchComments', batchComments());
      store.state.batchComments.drafts = [
        mockData.draftDiffDiscussion,
        mockData.draftReply,
        ...mockData.draftComments,
      ];
      store.state.isLoading = false;
      wrapper = shallowMount(NotesApp, {
        propsData,
        store,
        stubs: {
          OrderedLayout,
        },
      });
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
        store = createStore();
        initStore();
        wrapper = shallowMount(NotesApp, { propsData, store });
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
          store: createStore(),
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
      wrapper = mountComponent();
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
});
