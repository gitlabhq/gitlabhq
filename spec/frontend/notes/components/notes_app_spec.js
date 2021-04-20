import { mount, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import Vue from 'vue';
import { setTestTimeout } from 'helpers/timeout';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import CommentForm from '~/notes/components/comment_form.vue';
import NotesApp from '~/notes/components/notes_app.vue';
import * as constants from '~/notes/constants';
import createStore from '~/notes/stores';
import '~/behaviors/markdown/render_gfm';
// TODO: use generated fixture (https://gitlab.com/gitlab-org/gitlab-foss/issues/62491)
import OrderedLayout from '~/vue_shared/components/ordered_layout.vue';
import * as mockData from '../mock_data';

jest.mock('~/user_popovers', () => jest.fn());

setTestTimeout(1000);

const TYPE_COMMENT_FORM = 'comment-form';
const TYPE_NOTES_LIST = 'notes-list';

const propsData = {
  noteableData: mockData.noteableDataMock,
  notesData: mockData.notesDataMock,
  userData: mockData.userDataMock,
};

describe('note_app', () => {
  let axiosMock;
  let mountComponent;
  let wrapper;
  let store;

  const findCommentButton = () => wrapper.find('[data-testid="comment-button"]');

  const getComponentOrder = () => {
    return wrapper
      .findAll('#notes-list,.js-comment-form')
      .wrappers.map((node) => (node.is(CommentForm) ? TYPE_COMMENT_FORM : TYPE_NOTES_LIST));
  };

  /**
   * waits for fetchNotes() to complete
   */
  const waitForDiscussionsRequest = () =>
    new Promise((resolve) => {
      const { vm } = wrapper.find(NotesApp);
      const unwatch = vm.$watch('isFetching', (isFetching) => {
        if (isFetching) {
          return;
        }

        unwatch();
        resolve();
      });
    });

  beforeEach(() => {
    $('body').attr('data-page', 'projects:merge_requests:show');

    axiosMock = new AxiosMockAdapter(axios);

    store = createStore();
    mountComponent = () => {
      return mount(
        {
          components: {
            NotesApp,
          },
          template: `<div class="js-vue-notes-event">
            <notes-app ref="notesApp" v-bind="$attrs" />
          </div>`,
        },
        {
          propsData,
          store,
        },
      );
    };
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  describe('set data', () => {
    beforeEach(() => {
      setFixtures('<div class="js-discussions-count"></div>');

      axiosMock.onAny().reply(200, []);
      wrapper = mountComponent();
      return waitForDiscussionsRequest();
    });

    it('should set notes data', () => {
      expect(store.state.notesData).toEqual(mockData.notesDataMock);
    });

    it('should set issue data', () => {
      expect(store.state.noteableData).toEqual(mockData.noteableDataMock);
    });

    it('should set user data', () => {
      expect(store.state.userData).toEqual(mockData.userDataMock);
    });

    it('should fetch discussions', () => {
      expect(store.state.discussions).toEqual([]);
    });

    it('updates discussions badge', () => {
      expect(document.querySelector('.js-discussions-count').textContent).toEqual('0');
    });
  });

  describe('render', () => {
    beforeEach(() => {
      setFixtures('<div class="js-discussions-count"></div>');

      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      wrapper = mountComponent();
      return waitForDiscussionsRequest();
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

    it('should render form comment button as disabled', () => {
      expect(findCommentButton().props('disabled')).toEqual(true);
    });

    it('updates discussions badge', () => {
      expect(document.querySelector('.js-discussions-count').textContent).toEqual('2');
    });
  });

  describe('render with comments disabled', () => {
    beforeEach(() => {
      setFixtures('<div class="js-discussions-count"></div>');

      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      store.state.commentsDisabled = true;
      wrapper = mountComponent();
      return waitForDiscussionsRequest();
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
      setFixtures('<div class="js-discussions-count"></div>');

      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      store.state.commentsDisabled = false;
      store.state.isTimelineEnabled = true;

      wrapper = mountComponent();
      return waitForDiscussionsRequest();
    });

    it('should not render comments form', () => {
      expect(wrapper.find('.js-main-target-form').exists()).toBe(false);
    });
  });

  describe('while fetching data', () => {
    beforeEach(() => {
      setFixtures('<div class="js-discussions-count"></div>');
      axiosMock.onAny().reply(200, []);
      wrapper = mountComponent();
    });

    afterEach(() => waitForDiscussionsRequest());

    it('renders skeleton notes', () => {
      expect(wrapper.find('.animation-container').exists()).toBe(true);
    });

    it('should render form', () => {
      expect(wrapper.find('.js-main-target-form').element.tagName).toBe('FORM');
      expect(wrapper.find('.js-main-target-form textarea').attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });

    it('should not update discussions badge (it should be blank)', () => {
      expect(document.querySelector('.js-discussions-count').textContent).toEqual('');
    });
  });

  describe('update note', () => {
    describe('individual note', () => {
      beforeEach(() => {
        axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
        wrapper = mountComponent();
        return waitForDiscussionsRequest().then(() => {
          wrapper.find('.js-note-edit').trigger('click');
        });
      });

      it('renders edit form', () => {
        expect(wrapper.find('.js-vue-issue-note-form').exists()).toBe(true);
      });

      it('calls the store action to update the note', () => {
        jest.spyOn(axios, 'put').mockImplementation(() => Promise.resolve({ data: {} }));
        wrapper.find('.js-vue-issue-note-form').value = 'this is a note';
        wrapper.find('.js-vue-issue-save').trigger('click');

        expect(axios.put).toHaveBeenCalled();
      });
    });

    describe('discussion note', () => {
      beforeEach(() => {
        axiosMock.onAny().reply(mockData.getDiscussionNoteResponse);
        wrapper = mountComponent();
        return waitForDiscussionsRequest().then(() => {
          wrapper.find('.js-note-edit').trigger('click');
        });
      });

      it('renders edit form', () => {
        expect(wrapper.find('.js-vue-issue-note-form').exists()).toBe(true);
      });

      it('updates the note and resets the edit form', () => {
        jest.spyOn(axios, 'put').mockImplementation(() => Promise.resolve({ data: {} }));
        wrapper.find('.js-vue-issue-note-form').value = 'this is a note';
        wrapper.find('.js-vue-issue-save').trigger('click');

        expect(axios.put).toHaveBeenCalled();
      });
    });
  });

  describe('new note form', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      wrapper = mountComponent();
      return waitForDiscussionsRequest();
    });

    it('should render markdown docs url', () => {
      const { markdownDocsPath } = mockData.notesDataMock;

      expect(wrapper.find(`a[href="${markdownDocsPath}"]`).text().trim()).toEqual('Markdown');
    });

    it('should render quick action docs url', () => {
      const { quickActionsDocsPath } = mockData.notesDataMock;

      expect(wrapper.find(`a[href="${quickActionsDocsPath}"]`).text().trim()).toEqual(
        'quick actions',
      );
    });
  });

  describe('edit form', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(mockData.getIndividualNoteResponse);
      wrapper = mountComponent();
      return waitForDiscussionsRequest();
    });

    it('should render markdown docs url', () => {
      wrapper.find('.js-note-edit').trigger('click');
      const { markdownDocsPath } = mockData.notesDataMock;

      return Vue.nextTick().then(() => {
        expect(wrapper.find(`.edit-note a[href="${markdownDocsPath}"]`).text().trim()).toEqual(
          'Markdown is supported',
        );
      });
    });

    it('should not render quick actions docs url', () => {
      wrapper.find('.js-note-edit').trigger('click');
      const { quickActionsDocsPath } = mockData.notesDataMock;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(`.edit-note a[href="${quickActionsDocsPath}"]`).exists()).toBe(false);
      });
    });
  });

  describe('emoji awards', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(200, []);
      wrapper = mountComponent();
      return waitForDiscussionsRequest();
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
          stopPolling() {},
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
      return waitForDiscussionsRequest();
    });

    it('should listen hashchange event', () => {
      const notesApp = wrapper.find(NotesApp);
      const hash = 'some dummy hash';
      jest.spyOn(urlUtility, 'getLocationHash').mockReturnValueOnce(hash);
      const setTargetNoteHash = jest.spyOn(notesApp.vm, 'setTargetNoteHash');

      window.dispatchEvent(new Event('hashchange'), hash);

      expect(setTargetNoteHash).toHaveBeenCalled();
    });
  });

  describe('when sort direction is desc', () => {
    beforeEach(() => {
      store = createStore();
      store.state.discussionSortOrder = constants.DESC;
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
  });

  describe('when sort direction is asc', () => {
    beforeEach(() => {
      store = createStore();
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
      const drafts = wrapper.findAll(DraftNote).wrappers;

      expect(drafts.map((x) => x.props('draft'))).toEqual(
        mockData.draftComments.map(({ note }) => expect.objectContaining({ note })),
      );
    });
  });
});
