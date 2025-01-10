import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import setWindowLocation from 'helpers/set_window_location_helper';
import { setHTMLFixture } from 'helpers/fixtures';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemAddNote from '~/work_items/components/notes/work_item_add_note.vue';
import WorkItemNotesActivityHeader from '~/work_items/components/notes/work_item_notes_activity_header.vue';
import WorkItemNotesLoading from '~/work_items/components/notes/work_item_notes_loading.vue';
import workItemNoteQuery from '~/work_items/graphql/notes/work_item_note.query.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/notes/work_item_notes_by_iid.query.graphql';
import deleteWorkItemNoteMutation from '~/work_items/graphql/notes/delete_work_item_notes.mutation.graphql';
import workItemNoteCreatedSubscription from '~/work_items/graphql/notes/work_item_note_created.subscription.graphql';
import workItemNoteUpdatedSubscription from '~/work_items/graphql/notes/work_item_note_updated.subscription.graphql';
import workItemNoteDeletedSubscription from '~/work_items/graphql/notes/work_item_note_deleted.subscription.graphql';
import { DEFAULT_PAGE_SIZE_NOTES, WIDGET_TYPE_NOTES } from '~/work_items/constants';
import { ASC, DESC } from '~/notes/constants';
import { autocompleteDataSources, markdownPreviewPath } from '~/work_items/utils';
import {
  mockWorkItemNotesResponse,
  workItemQueryResponse,
  mockWorkItemNotesByIidResponse,
  mockMoreWorkItemNotesResponse,
  workItemNotesCreateSubscriptionResponse,
  workItemNotesUpdateSubscriptionResponse,
  workItemNotesDeleteSubscriptionResponse,
  mockWorkItemNotesResponseWithComments,
} from '../mock_data';

const mockWorkItemId = workItemQueryResponse.data.workItem.id;
const mockWorkItemIid = workItemQueryResponse.data.workItem.iid;

const mockNotesWidgetResponse = mockWorkItemNotesResponse.data.workItem.widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

const mockMoreNotesWidgetResponse =
  mockMoreWorkItemNotesResponse.data.workspace.workItem.widgets.find(
    (widget) => widget.type === WIDGET_TYPE_NOTES,
  );

const mockWorkItemNotesWidgetResponseWithComments =
  mockWorkItemNotesResponseWithComments().data.workspace.workItem.widgets.find(
    (widget) => widget.type === WIDGET_TYPE_NOTES,
  );

const firstSystemNodeId = mockNotesWidgetResponse.discussions.nodes[0].notes.nodes[0].id;

const mockDiscussions = mockWorkItemNotesWidgetResponseWithComments.discussions.nodes;

const mockWorkItemNoteResponse = {
  data: {
    note: {
      id: mockDiscussions[0].notes.nodes[0].id,
      discussion: { id: mockDiscussions[0].id, notes: mockDiscussions[0].notes },
    },
  },
};

describe('WorkItemNotes component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const showModal = jest.fn();

  const findAllSystemNotes = () => wrapper.findAllComponents(SystemNote);
  const findAllListItems = () => wrapper.findAll('ul.timeline > *');
  const findNotesLoading = () => wrapper.findComponent(WorkItemNotesLoading);
  const findActivityHeader = () => wrapper.findComponent(WorkItemNotesActivityHeader);
  const findSystemNoteAtIndex = (index) => findAllSystemNotes().at(index);
  const findAllWorkItemCommentNotes = () => wrapper.findAllComponents(WorkItemDiscussion);
  const findWorkItemCommentNoteAtIndex = (index) => findAllWorkItemCommentNotes().at(index);
  const findDeleteNoteModal = () => wrapper.findComponent(GlModal);
  const findWorkItemAddNote = () => wrapper.findComponent(WorkItemAddNote);

  const workItemNoteQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNoteResponse);
  const workItemNotesQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNotesByIidResponse);
  const workItemMoreNotesQueryHandler = jest.fn().mockResolvedValue(mockMoreWorkItemNotesResponse);
  const workItemNotesWithCommentsQueryHandler = jest
    .fn()
    .mockResolvedValue(mockWorkItemNotesResponseWithComments());
  const deleteWorkItemNoteMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: { destroyNote: { note: null, __typename: 'DestroyNote' } },
  });
  const notesCreateSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesCreateSubscriptionResponse);
  const notesUpdateSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesUpdateSubscriptionResponse);
  const notesDeleteSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesDeleteSubscriptionResponse);
  const errorHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

  const createComponent = ({
    workItemId = mockWorkItemId,
    workItemIid = mockWorkItemIid,
    defaultWorkItemNotesQueryHandler = workItemNotesQueryHandler,
    deleteWINoteMutationHandler = deleteWorkItemNoteMutationSuccessHandler,
    isGroup = false,
    isModal = false,
    isWorkItemConfidential = false,
    parentId = null,
  } = {}) => {
    wrapper = shallowMount(WorkItemNotes, {
      apolloProvider: createMockApollo([
        [workItemNoteQuery, workItemNoteQueryHandler],
        [workItemNotesByIidQuery, defaultWorkItemNotesQueryHandler],
        [deleteWorkItemNoteMutation, deleteWINoteMutationHandler],
        [workItemNoteCreatedSubscription, notesCreateSubscriptionHandler],
        [workItemNoteUpdatedSubscription, notesUpdateSubscriptionHandler],
        [workItemNoteDeletedSubscription, notesDeleteSubscriptionHandler],
      ]),
      provide: {
        isGroup,
      },
      propsData: {
        fullPath: 'test-path',
        workItemId,
        workItemIid,
        workItemType: 'task',
        reportAbusePath: '/report/abuse/path',
        isModal,
        isWorkItemConfidential,
        parentId,
      },
      stubs: {
        GlModal: stubComponent(GlModal, { methods: { show: showModal } }),
      },
    });
  };

  beforeEach(() => {
    setHTMLFixture('<div id="content-body"></div>');
    createComponent();
  });

  it('has the work item note activity header', () => {
    expect(findActivityHeader().exists()).toBe(true);
  });

  describe('when notes are loading', () => {
    it('renders skeleton loader', () => {
      expect(findNotesLoading().exists()).toBe(true);
    });

    it('does not render system notes', () => {
      expect(findAllSystemNotes().exists()).toBe(false);
    });

    it('skips query for target note if no note_id in URL', () => {
      createComponent();

      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
    });

    it('skips query for target note if invalid note_id in URL', () => {
      setWindowLocation('#not_a_note');

      createComponent();

      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
    });

    it('skips query for target note if note_id is for a synthetic note', () => {
      setWindowLocation('#note_517f0177a539a244bf9c5a720b6d6f376a268996');

      createComponent();

      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
    });

    it('skips preview note if modal is open', async () => {
      setWindowLocation('?show=true#note_174');

      const mockPreviewNote = {
        id: 'gid://gitlab/Note/174',
        discussion: { id: 'discussion-1' },
      };

      createComponent({
        propsData: {
          previewNote: mockPreviewNote,
        },
      });

      await waitForPromises();

      // Preview note should not be rendered when modal is open
      const discussions = wrapper.findAllComponents(WorkItemDiscussion);
      expect(discussions.length).toBe(0);

      // Should still show loading state
      expect(findNotesLoading().exists()).toBe(true);
    });

    it('makes query for target note if note_id in URL', () => {
      setWindowLocation('#note_174');

      createComponent();

      expect(workItemNoteQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/Note/174',
      });
    });

    it('renders note above skeleton notes once loaded', async () => {
      setWindowLocation('#note_174');

      createComponent();

      await waitForPromises();

      expect(findWorkItemCommentNoteAtIndex(0).props('discussion')).toEqual(
        mockWorkItemNoteResponse.data.note.discussion.notes.nodes,
      );
    });
  });

  describe('when notes have been loaded', () => {
    it('does not render skeleton loader', async () => {
      await waitForPromises();

      expect(findNotesLoading().exists()).toBe(true);
    });

    it('renders system notes to the length of the response', async () => {
      await waitForPromises();
      expect(workItemNotesQueryHandler).toHaveBeenCalledWith({
        after: undefined,
        fullPath: 'test-path',
        iid: '1',
        pageSize: 20,
      });
      expect(findAllSystemNotes()).toHaveLength(mockNotesWidgetResponse.discussions.nodes.length);
    });
  });

  describe('Pagination', () => {
    describe('When there is no next page', () => {
      it('fetch more notes is not called', async () => {
        createComponent();
        await nextTick();
        expect(workItemMoreNotesQueryHandler).not.toHaveBeenCalled();
      });
    });

    describe('when there is next page', () => {
      beforeEach(async () => {
        createComponent({ defaultWorkItemNotesQueryHandler: workItemMoreNotesQueryHandler });
        await waitForPromises();
      });

      it('fetch more notes should be called', async () => {
        expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
          fullPath: 'test-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
        });

        await nextTick();

        expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
          fullPath: 'test-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
          after: mockMoreNotesWidgetResponse.discussions.pageInfo.endCursor,
        });
      });
    });
  });

  describe('Sorting', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('sorts the list when the `changeSort` event is emitted', async () => {
      expect(findSystemNoteAtIndex(0).props('note').id).toEqual(firstSystemNodeId);

      await findActivityHeader().vm.$emit('changeSort', DESC);

      expect(findSystemNoteAtIndex(0).props('note').id).not.toEqual(firstSystemNodeId);
    });

    it('puts form at start of list in when sorting by newest first', async () => {
      findActivityHeader().vm.$emit('changeSort', DESC);
      await nextTick();

      expect(findAllListItems().at(0).element.tagName).toBe('WORK-ITEM-ADD-NOTE-STUB');
    });

    it('puts form at end of list in when sorting by oldest first', async () => {
      findActivityHeader().vm.$emit('changeSort', ASC);
      await nextTick();

      const lastIndex = findAllListItems().length - 1;
      expect(findAllListItems().at(lastIndex).element.tagName).toBe('WORK-ITEM-ADD-NOTE-STUB');
    });
  });

  describe('Activity comments', () => {
    beforeEach(async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      });
      await waitForPromises();
    });

    it('should not have any system notes', () => {
      expect(workItemNotesWithCommentsQueryHandler).toHaveBeenCalled();
      expect(findAllSystemNotes()).toHaveLength(0);
    });

    it('should have work item notes', () => {
      expect(workItemNotesWithCommentsQueryHandler).toHaveBeenCalled();
      expect(findAllWorkItemCommentNotes()).toHaveLength(mockDiscussions.length);
    });

    it('should pass all the correct props to work item comment note', () => {
      const commentIndex = 0;
      const firstCommentNote = findWorkItemCommentNoteAtIndex(commentIndex);

      expect(firstCommentNote.props()).toMatchObject({
        discussion: mockDiscussions[commentIndex].notes.nodes,
        autocompleteDataSources: autocompleteDataSources({
          fullPath: 'test-path',
          iid: mockWorkItemIid,
        }),
        markdownPreviewPath: markdownPreviewPath({
          fullPath: 'test-path',
          iid: mockWorkItemIid,
        }),
      });
    });
  });

  it('should open delete modal confirmation when child discussion emits `deleteNote` event', async () => {
    createComponent({
      defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
    });
    await waitForPromises();

    findWorkItemCommentNoteAtIndex(0).vm.$emit('deleteNote', { id: '1', isLastNote: false });
    expect(showModal).toHaveBeenCalled();
  });

  describe('when modal is open', () => {
    beforeEach(() => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      });
      return waitForPromises();
    });

    it('sends the mutation with correct variables', () => {
      const noteId = 'some-test-id';

      findWorkItemCommentNoteAtIndex(0).vm.$emit('deleteNote', { id: noteId });
      findDeleteNoteModal().vm.$emit('primary');

      expect(deleteWorkItemNoteMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: noteId,
        },
      });
    });

    it('successfully removes the note from the discussion', async () => {
      expect(findWorkItemCommentNoteAtIndex(0).props('discussion')).toHaveLength(2);

      findWorkItemCommentNoteAtIndex(0).vm.$emit('deleteNote', {
        id: mockDiscussions[0].notes.nodes[0].id,
      });
      findDeleteNoteModal().vm.$emit('primary');

      await waitForPromises();
      expect(findWorkItemCommentNoteAtIndex(0).props('discussion')).toHaveLength(1);
    });

    it('successfully removes the discussion from work item if discussion only had one note', async () => {
      const secondDiscussion = findWorkItemCommentNoteAtIndex(1);

      expect(findAllWorkItemCommentNotes()).toHaveLength(2);
      expect(secondDiscussion.props('discussion')).toHaveLength(1);

      secondDiscussion.vm.$emit('deleteNote', {
        id: mockDiscussions[1].notes.nodes[0].id,
        discussion: { id: mockDiscussions[1].id },
      });
      findDeleteNoteModal().vm.$emit('primary');

      await waitForPromises();
      expect(findAllWorkItemCommentNotes()).toHaveLength(1);
    });
  });

  it('emits `error` event if delete note mutation is rejected', async () => {
    createComponent({
      defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      deleteWINoteMutationHandler: errorHandler,
    });
    await waitForPromises();

    findWorkItemCommentNoteAtIndex(0).vm.$emit('deleteNote', {
      id: mockDiscussions[0].notes.nodes[0].id,
    });
    findDeleteNoteModal().vm.$emit('primary');

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([
      ['Something went wrong when deleting a comment. Please try again'],
    ]);
  });

  describe('Notes subscriptions', () => {
    beforeEach(async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      });
      await waitForPromises();
    });

    it('has create notes subscription', () => {
      expect(notesCreateSubscriptionHandler).toHaveBeenCalledWith({
        noteableId: mockWorkItemId,
      });
    });

    it('has delete notes subscription', () => {
      expect(notesDeleteSubscriptionHandler).toHaveBeenCalledWith({
        noteableId: mockWorkItemId,
      });
    });

    it('has update notes subscription', () => {
      expect(notesUpdateSubscriptionHandler).toHaveBeenCalledWith({
        noteableId: mockWorkItemId,
      });
    });
  });

  it('passes confidential props when the work item is confidential', async () => {
    createComponent({
      isWorkItemConfidential: true,
      defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
    });
    await waitForPromises();

    expect(findWorkItemCommentNoteAtIndex(0).props('isWorkItemConfidential')).toBe(true);
  });

  describe('when project context', () => {
    it('calls the project work item query', async () => {
      createComponent();
      await waitForPromises();

      expect(workItemNotesQueryHandler).toHaveBeenCalled();
    });
  });

  describe('discussions expanded status', () => {
    it('should be expanded when the discussion is not resolved', async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      });
      await waitForPromises();
      expect(findAllWorkItemCommentNotes().at(0).props('isExpandedOnLoad')).toBe(true);
    });

    it('should be collapsed when the discussion is resolved', async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: jest
          .fn()
          .mockResolvedValue(mockWorkItemNotesResponseWithComments(true)),
      });

      await waitForPromises();
      expect(findAllWorkItemCommentNotes().at(0).props('isExpandedOnLoad')).toBe(false);
    });

    it('should be expanded when the notes are resolved but the target note hash has note id', async () => {
      setWindowLocation('#note_174');

      createComponent({
        defaultWorkItemNotesQueryHandler: jest
          .fn()
          .mockResolvedValue(mockWorkItemNotesResponseWithComments(true)),
      });

      await waitForPromises();
      await nextTick();

      expect(findAllWorkItemCommentNotes().at(0).props('isExpandedOnLoad')).toBe(true);
    });
  });

  describe('when group context', () => {
    it('should pass the correct `autoCompleteDataSources` to group work item comment note', async () => {
      const groupWorkItemNotes = {
        data: {
          workspace: {
            id: 'gid://gitlab/Group/24',
            workItem: {
              ...mockWorkItemNotesResponseWithComments().data.workspace.workItem,
              namespace: {
                id: 'gid://gitlab/Group/24',
                __typename: 'Namespace',
              },
            },
          },
        },
      };
      createComponent({
        isGroup: true,
        defaultWorkItemNotesQueryHandler: jest.fn().mockResolvedValue(groupWorkItemNotes),
      });
      await waitForPromises();

      expect(findWorkItemAddNote().props('autocompleteDataSources')).toEqual(
        autocompleteDataSources({
          fullPath: 'test-path',
          iid: mockWorkItemIid,
          isGroup: true,
        }),
      );
    });
  });

  it('passes the `parentId` prop down to the `WorkItemAddNote` component', async () => {
    createComponent({ parentId: 'example-id' });
    await waitForPromises();

    expect(findWorkItemAddNote().props('parentId')).toBe('example-id');
  });
});
