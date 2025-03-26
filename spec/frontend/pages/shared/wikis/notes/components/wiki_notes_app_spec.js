import { GlAlert } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiNotesApp from '~/pages/shared/wikis/wiki_notes/components/wiki_notes_app.vue';
import WikiCommentForm from '~/pages/shared/wikis/wiki_notes/components/wiki_comment_form.vue';
import PlaceholderNote from '~/pages/shared/wikis/wiki_notes/components/placeholder_note.vue';
import SkeletonNote from '~/vue_shared/components/notes/skeleton_note.vue';
import WikiDiscussion from '~/pages/shared/wikis/wiki_notes/components/wiki_discussion.vue';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import WikiNotesActivityHeader from '~/pages/shared/wikis/wiki_notes/components/wiki_notes_activity_header.vue';
import eventHub, {
  EVENT_EDIT_WIKI_DONE,
  EVENT_EDIT_WIKI_START,
} from '~/pages/shared/wikis/event_hub';
import createMockApollo from 'helpers/mock_apollo_helper';
import { noteableId, queryVariables } from '../mock_data';

Vue.use(VueApollo);

const mockDiscussion = (...children) => {
  return {
    __typename: 'Discussion',
    id: uniqueId(),
    replyId: uniqueId(),
    resolvable: false,
    resolved: false,
    resolvedAt: null,
    resolvedBy: null,
    notes: {
      nodes: children.map((c) => ({
        __typename: 'Note',
        id: uniqueId(),
        author: null,
        body: c,
        bodyHtml: c,
        createdAt: '2023-05-18T14:24:07.000+00:00',
        lastEditedAt: null,
        lastEditedBy: null,
        url: 'https://path/to/2/',
        awardEmoji: null,
        userPermissions: {
          adminNote: true,
          awardEmoji: true,
          readNote: true,
          createNote: true,
          resolveNote: true,
          repositionNote: true,
        },
        discussion: null,
      })),
    },
  };
};

const apolloCache = {
  writeQuery: jest.fn(),
  readQuery: jest.fn(),
};

describe('WikiNotesApp', () => {
  let wrapper;
  let fakeApollo;

  const createWrapper = async ({
    provideData = { queryVariables },
    mockQueryResponse = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [
        wikiPageQuery,
        jest.fn().mockResolvedValue({
          data: {
            wikiPage: {
              id: 'gid://gitlab/WikiPage/1',
              title: 'home',
              discussions: {
                nodes: [mockDiscussion('Discussion 1')],
              },
            },
            ...mockQueryResponse,
          },
        }),
      ],
    ]);

    fakeApollo.clients.defaultClient.cache = apolloCache;
    fakeApollo.queries = {
      wikiPage: {
        loading: false,
        refetch: jest.fn().mockResolvedValue({}),
      },
    };

    wrapper = shallowMountExtended(WikiNotesApp, {
      apolloProvider: fakeApollo,
      data() {
        return {
          wikiPage: {
            id: 'gid://gitlab/WikiPage/1',
            title: 'home',
            discussions: {
              nodes: [mockDiscussion('Discussion 1')],
            },
          },
          ...mockQueryResponse,
        };
      },
      provide: {
        containerId: noteableId,
        noteCount: 5,
        ...provideData,
      },
    });

    await nextTick();
  };

  let wikiPage = {};
  beforeEach(async () => {
    await createWrapper();

    wikiPage = {
      id: noteableId,
      discussions: {
        nodes: [],
      },
    };

    // stub apollo's cache read, and add some default data with the wikiPage result method
    apolloCache.readQuery.mockReturnValue({
      noteableId,
      wikiPage,
    });

    wrapper.vm.$options.apollo.wikiPage.result.call(wrapper.vm, { data: {} });
  });

  describe('when editing a wiki page', () => {
    beforeEach(async () => {
      eventHub.$emit(EVENT_EDIT_WIKI_START);

      await nextTick();
    });

    it('should hide notes when editing a wiki page', () => {
      expect(wrapper.findComponent(WikiNotesActivityHeader).exists()).toBe(false);
    });

    it('should show notes when editing a wiki page is done', async () => {
      eventHub.$emit(EVENT_EDIT_WIKI_DONE);

      await nextTick();

      expect(wrapper.findComponent(WikiNotesActivityHeader).exists()).toBe(true);
    });
  });

  it('should render skeleton notes before content loads', () => {
    createWrapper();
    const skeletonNotes = wrapper.findAllComponents(SkeletonNote);

    expect(skeletonNotes.length).toBe(5);
  });

  it('should render Comment Form correctly', () => {
    const commentForm = wrapper.findComponent(WikiCommentForm);

    expect(commentForm.props()).toMatchObject({
      noteableId: 'gid://gitlab/WikiPage/1',
      noteId: 'gid://gitlab/WikiPage/1',
    });
  });

  it('should not render placeholder note by default', () => {
    const placeholderNote = wrapper.findComponent(PlaceholderNote);
    expect(placeholderNote.exists()).toBe(false);
  });

  it('should render placeholder note correctly when set', async () => {
    wrapper.vm.setPlaceHolderNote({ body: 'a placeholder' });
    await nextTick();

    const placeholderNote = wrapper.findComponent(PlaceholderNote);

    expect(placeholderNote.props('note')).toMatchObject({ body: 'a placeholder' });
  });

  describe('when there is an error while fetching discussions', () => {
    beforeEach(() => {
      wrapper.vm.$options.apollo.wikiPage.error.call(wrapper.vm);
    });

    it('should render error message correctly', async () => {
      const errorAlert = wrapper.findComponent(GlAlert);
      expect(await errorAlert.text()).toBe(
        'Something went wrong while fetching comments. Please refresh the page.',
      );
    });

    it('should render retry text correctly', async () => {
      const errorAlert = wrapper.findComponent(GlAlert);
      expect(await errorAlert.props('primaryButtonText')).toBe('Retry');
    });

    it('should not render any discussions', () => {
      const wikiDiscussions = wrapper.findAllComponents(WikiDiscussion);
      expect(wikiDiscussions.length).toBe(0);
    });

    it('should not render any skeleton notes', () => {
      const skeletonNotes = wrapper.findAllComponents(SkeletonNote);
      expect(skeletonNotes.length).toBe(0);
    });

    it('should attempt to fetch Discussions when retry button is clicked', async () => {
      const errorAlert = wrapper.findComponent(GlAlert);

      jest.spyOn(wrapper.vm.$apollo.queries.wikiPage, 'refetch');
      await errorAlert.vm.$emit('primaryAction');
      expect(wrapper.vm.$apollo.queries.wikiPage.refetch).toHaveBeenCalled();
    });
  });

  describe('when there are no errors while fetching discussions', () => {
    let discussions;
    beforeEach(async () => {
      discussions = {
        nodes: [
          mockDiscussion('Discussion 1'),
          mockDiscussion('Discussion 2'),
          mockDiscussion('Discussion 3 Note 1', 'Discussion 3 Note 2', 'Discussion 3 Note 3'),
        ],
      };

      await createWrapper({
        mockQueryResponse: {
          wikiPage: {
            id: 'gid://gitlab/WikiPage/1',
            title: 'home',
            discussions,
          },
        },
      });
    });

    it('should render discussions correctly', () => {
      const wikiDiscussions = wrapper.findAllComponents(WikiDiscussion);

      expect(wikiDiscussions.length).toBe(3);
      expect(wikiDiscussions.at(0).props('noteableId')).toEqual('gid://gitlab/WikiPage/1');
      expect(wikiDiscussions.at(1).props('noteableId')).toEqual('gid://gitlab/WikiPage/1');
      expect(wikiDiscussions.at(2).props('noteableId')).toEqual('gid://gitlab/WikiPage/1');

      expect(wikiDiscussions.at(0).props('discussion')).toHaveLength(1);
      expect(wikiDiscussions.at(1).props('discussion')).toHaveLength(1);
      expect(wikiDiscussions.at(2).props('discussion')).toHaveLength(3);

      expect(wikiDiscussions.at(0).props('discussion')[0].body).toEqual('Discussion 1');
      expect(wikiDiscussions.at(1).props('discussion')[0].body).toEqual('Discussion 2');
      expect(wikiDiscussions.at(2).props('discussion')[0].body).toEqual('Discussion 3 Note 1');
      expect(wikiDiscussions.at(2).props('discussion')[1].body).toEqual('Discussion 3 Note 2');
      expect(wikiDiscussions.at(2).props('discussion')[2].body).toEqual('Discussion 3 Note 3');
    });

    it('should not render error alert', () => {
      const errorAlert = wrapper.findComponent(GlAlert);
      expect(errorAlert.exists()).toBe(false);
    });
  });

  describe('when "note-deleted" is fired', () => {
    let discussions;
    beforeEach(async () => {
      discussions = {
        nodes: [
          mockDiscussion('Discussion 1'),
          mockDiscussion('Discussion 2'),
          mockDiscussion('Discussion 3 Note 1', 'Discussion 3 Note 2', 'Discussion 3 Note 3'),
        ],
      };

      await createWrapper({
        mockQueryResponse: {
          wikiPage: {
            id: 'gid://gitlab/WikiPage/1',
            title: 'home',
            discussions,
          },
        },
      });
    });

    it('should call write query with the correct data', async () => {
      wrapper.findComponent(WikiDiscussion).vm.$emit('note-deleted');
      await nextTick();

      expect(apolloCache.writeQuery).toHaveBeenCalledWith({
        query: wikiPageQuery,
        variables: queryVariables,
        data: { noteableId: '7', wikiPage },
      });
    });

    it('should delete note correctly when there are no replies', async () => {
      wrapper.findComponent(WikiDiscussion).vm.$emit('note-deleted');
      await nextTick();

      expect(wrapper.findAllComponents(WikiDiscussion)).toHaveLength(2);
    });

    it('should delete note correctly when there are replies', async () => {
      const wikiDiscussions = wrapper.findAllComponents(WikiDiscussion);

      // delete first note
      wikiDiscussions.at(2).vm.$emit('note-deleted', discussions.nodes[2].notes.nodes[0].id);
      await nextTick();

      const findNotes = () => wikiDiscussions.at(2).props('discussion');
      expect(findNotes()).toHaveLength(2);
      expect(findNotes()).not.toContainEqual({
        id: discussions.nodes[2].notes.nodes[0].id,
        body: 'Discussion 3 Note 1',
      });

      // delete last note
      wikiDiscussions.at(2).vm.$emit('note-deleted', discussions.nodes[2].notes.nodes[2].id);
      await nextTick();

      expect(findNotes()).toHaveLength(1);
      expect(findNotes()).toMatchObject([
        {
          id: discussions.nodes[2].notes.nodes[1].id,
          body: 'Discussion 3 Note 2',
        },
      ]);

      // delete remaning note
      wikiDiscussions.at(2).vm.$emit('note-deleted', 2);
      await nextTick();

      expect(wrapper.findAllComponents(WikiDiscussion)).toHaveLength(2);
    });
  });

  describe('when fetching discussions', () => {
    const setUpAndReturnVariables = (id) => {
      createWrapper({ provideData: { queryVariables: { ...queryVariables, ...id } } });

      const variablesSpy = jest.spyOn(WikiNotesApp.apollo.wikiPage, 'variables');
      WikiNotesApp.apollo.wikiPage.variables.call(wrapper.vm);

      expect(wrapper.vm.$options.apollo.wikiPage.query).toBe(wikiPageQuery);
      return variablesSpy.mock.results[0].value;
    };

    it('should set variable data when containerType is group', () => {
      const variables = setUpAndReturnVariables({ namespaceId: 'gid://gitlab/Group/7' });
      expect(variables).toMatchObject({ slug: 'home', namespaceId: 'gid://gitlab/Group/7' });
    });

    it('should set variable data when containerType is project', () => {
      const variables = setUpAndReturnVariables({ projectId: 'gid://gitlab/Project/7' });

      expect(variables).toMatchObject({ slug: 'home', projectId: 'gid://gitlab/Project/7' });
    });
  });

  describe('wiki comment form', () => {
    it('should setPlaceHolder correctly when "creating-note:start" is called', async () => {
      const commentForm = wrapper.findComponent(WikiCommentForm);

      commentForm.vm.$emit('creating-note:start', { body: 'example placeholder' });
      await nextTick();

      const placeholderNote = wrapper.findComponent(PlaceholderNote);
      expect(placeholderNote.props('note')).toMatchObject({ body: 'example placeholder' });
    });

    it('should removePlaceholder when "creating-note:done" is called', async () => {
      wrapper.vm.setPlaceHolderNote({ body: 'example placeholder' });
      const commentForm = wrapper.findComponent(WikiCommentForm);
      commentForm.vm.$emit('creating-note:done');
      await nextTick();

      expect(wrapper.vm.placeholderNote).toMatchObject({});
    });

    it('should call writeQuery with the correct data when "creating-note:success" is called', async () => {
      const newDiscussion = {
        id: '2',
      };
      const commentForm = wrapper.findComponent(WikiCommentForm);
      commentForm.vm.$emit('creating-note:success', newDiscussion);
      await nextTick();

      wikiPage.discussions.nodes.push({
        ...newDiscussion,
        replyId: null,
        resolvable: false,
        resolved: false,
        resolvedAt: null,
        resolvedBy: null,
      });

      expect(apolloCache.writeQuery).toHaveBeenCalledWith({
        query: wikiPageQuery,
        variables: queryVariables,
        data: {
          noteableId: '7',
          wikiPage,
        },
      });
    });
  });
});
