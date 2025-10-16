import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import setWindowLocation from 'helpers/set_window_location_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { Mousetrap } from '~/lib/mousetrap';
import { ISSUABLE_COMMENT_OR_REPLY, keysFor } from '~/behaviors/shortcuts/keybindings';
import gfmEventHub from '~/vue_shared/components/markdown/eventhub';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemAddNote from '~/work_items/components/notes/work_item_add_note.vue';
import WorkItemNotesActivityHeader from '~/work_items/components/notes/work_item_notes_activity_header.vue';
import WorkItemNotesLoading from '~/work_items/components/notes/work_item_notes_loading.vue';
import workItemNoteQuery from '~/work_items/graphql/notes/work_item_note.query.graphql';
import namespacePathsQuery from '~/work_items/graphql/namespace_paths.query.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/notes/work_item_notes_by_iid.query.graphql';
import deleteWorkItemNoteMutation from '~/work_items/graphql/notes/delete_work_item_notes.mutation.graphql';
import workItemNoteCreatedSubscription from '~/work_items/graphql/notes/work_item_note_created.subscription.graphql';
import workItemNoteUpdatedSubscription from '~/work_items/graphql/notes/work_item_note_updated.subscription.graphql';
import workItemNoteDeletedSubscription from '~/work_items/graphql/notes/work_item_note_deleted.subscription.graphql';
import {
  DEFAULT_PAGE_SIZE_NOTES,
  WIDGET_TYPE_NOTES,
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
} from '~/work_items/constants';
import { ASC, DESC, DISCUSSIONS_SORT_ENUM } from '~/notes/constants';
import {
  workItemQueryResponse,
  mockWorkItemNotesByIidResponse,
  mockWorkItemNotesResponse,
  mockMoreWorkItemNotesResponse,
  namespacePathsQueryResponse,
  workItemNotesCreateSubscriptionResponse,
  workItemNotesUpdateSubscriptionResponse,
  workItemNotesDeleteSubscriptionResponse,
  mockWorkItemNotesResponseWithComments,
} from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/lib/utils/resize_observer', () => ({
  scrollToTargetOnResize: jest.fn(),
}));

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
  const findAllWorkItemDiscussions = () => wrapper.findAllComponents(WorkItemDiscussion);
  const findWorkItemDiscussionAtIndex = (index) => findAllWorkItemDiscussions().at(index);
  const findDeleteNoteModal = () => wrapper.findComponent(GlModal);
  const findWorkItemAddNote = () => wrapper.findComponent(WorkItemAddNote);
  const findCommentsSection = () => wrapper.find('.issuable-discussion');

  const { markdownPaths } = namespacePathsQueryResponse.data.namespace;

  const workItemNoteQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNoteResponse);
  const workItemNotesQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNotesByIidResponse);
  const workItemMoreNotesQueryHandler = jest.fn().mockResolvedValue(mockMoreWorkItemNotesResponse);
  const workItemNotesWithCommentsQueryHandler = jest
    .fn()
    .mockResolvedValue(mockWorkItemNotesResponseWithComments());
  const mockNamespacePathsHandler = jest.fn().mockResolvedValue(namespacePathsQueryResponse);
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
    canCreateNote = false,
    isDrawer = false,
    isModal = false,
    isWorkItemConfidential = false,
    parentId = null,
    propsData = {},
    isGroup = false,
  } = {}) => {
    setHTMLFixture(`
      <div class="work-item-overview">
        <div class="js-work-item-description">
          <p>Work Item Description</p>
        </div>
        <div id="root"></div>
      </div>
    `);
    wrapper = shallowMount(WorkItemNotes, {
      attachTo: '#root',
      apolloProvider: createMockApollo(
        [
          [workItemNoteQuery, workItemNoteQueryHandler],
          [namespacePathsQuery, mockNamespacePathsHandler],
          [workItemNotesByIidQuery, defaultWorkItemNotesQueryHandler],
          [deleteWorkItemNoteMutation, deleteWINoteMutationHandler],
          [workItemNoteCreatedSubscription, notesCreateSubscriptionHandler],
          [workItemNoteUpdatedSubscription, notesUpdateSubscriptionHandler],
          [workItemNoteDeletedSubscription, notesDeleteSubscriptionHandler],
        ],
        {},
        {
          typePolicies: {
            Namespace: {
              merge: true,
            },
          },
        },
      ),
      provide: {
        isGroup,
      },
      propsData: {
        fullPath: 'test-path',
        workItemId,
        workItemIid,
        workItemType: 'task',
        workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
        isDrawer,
        isModal,
        isWorkItemConfidential,
        parentId,
        canCreateNote,
        ...propsData,
      },
      stubs: {
        GlModal: stubComponent(GlModal, { methods: { show: showModal } }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('has the work item note activity header', () => {
    expect(findActivityHeader().exists()).toBe(true);
  });

  describe('when notes are loading', () => {
    it('renders skeleton loader', () => {
      expect(findNotesLoading().exists()).toBe(true);
    });

    it('renders the main discussion container even when notes are loading', () => {
      expect(findCommentsSection().exists()).toBe(true);
    });

    it('does not render the comment form when markdownPaths is loading', () => {
      expect(findWorkItemAddNote().exists()).toBe(false);
    });

    it('does not render system notes', () => {
      expect(findAllSystemNotes().exists()).toBe(false);
    });

    it('skips query for target note if no note_id in URL', () => {
      createComponent();

      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
      expect(scrollToTargetOnResize).not.toHaveBeenCalled();
    });

    it('skips query for target note if invalid note_id in URL', () => {
      setWindowLocation('#not_a_note');

      createComponent();

      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
      expect(scrollToTargetOnResize).not.toHaveBeenCalled();
    });

    it('skips query for target note if note_id is for a synthetic note', () => {
      setWindowLocation('#note_517f0177a539a244bf9c5a720b6d6f376a268996');

      createComponent();

      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
      expect(scrollToTargetOnResize).not.toHaveBeenCalled();
    });

    it('skips preview note if modal is open', async () => {
      const mockPreviewNote = {
        id: 'gid://gitlab/Note/174',
        discussion: { id: 'discussion-1' },
      };

      createComponent({
        propsData: {
          previewNote: mockPreviewNote,
          isModal: true,
        },
      });

      await waitForPromises();

      // Preview note should not be rendered when modal is open
      const discussions = wrapper.findAllComponents(WorkItemDiscussion);
      expect(discussions).toHaveLength(0);

      // Should still show loading state
      expect(findNotesLoading().exists()).toBe(true);
      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
      expect(scrollToTargetOnResize).not.toHaveBeenCalled();
    });

    it('skips preview note if open in drawer', async () => {
      const mockPreviewNote = {
        id: 'gid://gitlab/Note/174',
        discussion: { id: 'discussion-1' },
      };

      createComponent({
        propsData: {
          previewNote: mockPreviewNote,
          isDrawer: true,
        },
      });

      await waitForPromises();

      // Preview note should not be rendered when modal is open
      const discussions = wrapper.findAllComponents(WorkItemDiscussion);
      expect(discussions).toHaveLength(0);

      // Should still show loading state
      expect(findNotesLoading().exists()).toBe(true);
      expect(workItemNoteQueryHandler).not.toHaveBeenCalled();
      expect(scrollToTargetOnResize).not.toHaveBeenCalled();
    });

    it('makes query for target note if note_id in URL', () => {
      setWindowLocation('#note_174');

      createComponent();

      expect(scrollToTargetOnResize).toHaveBeenCalled();
      expect(workItemNoteQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/Note/174',
      });
    });

    it('renders note above skeleton notes once loaded', async () => {
      setWindowLocation('#note_174');

      createComponent();

      await waitForPromises();

      expect(findWorkItemDiscussionAtIndex(0).props('discussion')).toEqual(
        mockWorkItemNoteResponse.data.note.discussion,
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
        sort: DISCUSSIONS_SORT_ENUM[ASC],
      });
      expect(findAllSystemNotes()).toHaveLength(mockNotesWidgetResponse.discussions.nodes.length);
    });

    it('renders the main discussion container when notes are loaded', async () => {
      await waitForPromises();
      expect(findCommentsSection().exists()).toBe(true);
    });

    it('renders the comment form even when notes are loaded', async () => {
      await waitForPromises();
      expect(findWorkItemAddNote().exists()).toBe(true);
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
      it('fetch more notes should be called', async () => {
        createComponent({ defaultWorkItemNotesQueryHandler: workItemMoreNotesQueryHandler });
        await waitForPromises();

        expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
          fullPath: 'test-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
          sort: DISCUSSIONS_SORT_ENUM[ASC],
        });

        await nextTick();

        expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
          fullPath: 'test-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
          after: mockMoreNotesWidgetResponse.discussions.pageInfo.endCursor,
          sort: DISCUSSIONS_SORT_ENUM[ASC],
        });
      });

      describe('when sort order is set to newest first by default', () => {
        it('fetches notes in descending order', async () => {
          useLocalStorageSpy();
          localStorage.setItem(WORK_ITEM_NOTES_SORT_ORDER_KEY, DESC);

          createComponent({ defaultWorkItemNotesQueryHandler: workItemMoreNotesQueryHandler });
          await waitForPromises();

          expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
            fullPath: 'test-path',
            iid: '1',
            pageSize: DEFAULT_PAGE_SIZE_NOTES,
            sort: DISCUSSIONS_SORT_ENUM[DESC],
          });

          await nextTick();

          expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
            fullPath: 'test-path',
            iid: '1',
            pageSize: DEFAULT_PAGE_SIZE_NOTES,
            after: mockMoreNotesWidgetResponse.discussions.pageInfo.endCursor,
            sort: DISCUSSIONS_SORT_ENUM[DESC],
          });
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
      expect(findAllWorkItemDiscussions()).toHaveLength(mockDiscussions.length);
    });

    it('should pass all the correct props to work item comment note', () => {
      const commentIndex = 0;
      const firstDiscussion = findWorkItemDiscussionAtIndex(commentIndex);

      expect(firstDiscussion.props()).toMatchObject({
        discussion: mockDiscussions[commentIndex],
        autocompleteDataSources: markdownPaths.autocompleteSourcesPath,
        markdownPreviewPath: markdownPaths.markdownPreviewPath,
      });
    });
  });

  it('should open delete modal confirmation when child discussion emits `deleteNote` event', async () => {
    createComponent({
      defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
    });
    await waitForPromises();

    findWorkItemDiscussionAtIndex(0).vm.$emit('deleteNote', { id: '1', isLastNote: false });
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

      findWorkItemDiscussionAtIndex(0).vm.$emit('deleteNote', { id: noteId });
      findDeleteNoteModal().vm.$emit('primary');

      expect(deleteWorkItemNoteMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: noteId,
        },
      });
    });

    it('successfully removes the note from the discussion', async () => {
      expect(findWorkItemDiscussionAtIndex(0).props('discussion').notes.nodes).toHaveLength(2);

      findWorkItemDiscussionAtIndex(0).vm.$emit('deleteNote', {
        id: mockDiscussions[0].notes.nodes[0].id,
      });
      findDeleteNoteModal().vm.$emit('primary');

      await waitForPromises();
      expect(findWorkItemDiscussionAtIndex(0).props('discussion').notes.nodes).toHaveLength(1);
    });

    it('successfully removes the discussion from work item if discussion only had one note', async () => {
      const secondDiscussion = findWorkItemDiscussionAtIndex(1);

      expect(findAllWorkItemDiscussions()).toHaveLength(2);
      expect(secondDiscussion.props('discussion').notes.nodes).toHaveLength(1);

      secondDiscussion.vm.$emit('deleteNote', {
        id: mockDiscussions[1].notes.nodes[0].id,
        discussion: { id: mockDiscussions[1].id },
      });
      findDeleteNoteModal().vm.$emit('primary');

      await waitForPromises();
      expect(findAllWorkItemDiscussions()).toHaveLength(1);
    });
  });

  it('emits `error` event if delete note mutation is rejected', async () => {
    createComponent({
      defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      deleteWINoteMutationHandler: errorHandler,
    });
    await waitForPromises();

    findWorkItemDiscussionAtIndex(0).vm.$emit('deleteNote', {
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

    expect(findWorkItemDiscussionAtIndex(0).props('isWorkItemConfidential')).toBe(true);
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
      expect(findAllWorkItemDiscussions().at(0).props('isExpandedOnLoad')).toBe(true);
    });

    it('should be collapsed when the discussion is resolved', async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: jest
          .fn()
          .mockResolvedValue(mockWorkItemNotesResponseWithComments(true)),
      });

      await waitForPromises();
      expect(findAllWorkItemDiscussions().at(0).props('isExpandedOnLoad')).toBe(false);
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

      expect(findAllWorkItemDiscussions().at(0).props('isExpandedOnLoad')).toBe(true);
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
        defaultWorkItemNotesQueryHandler: jest.fn().mockResolvedValue(groupWorkItemNotes),
        isGroup: true,
      });
      await waitForPromises();

      expect(findWorkItemAddNote().props('autocompleteDataSources')).toEqual({
        ...markdownPaths.autocompleteSourcesPath,
        statuses: true,
      });
    });
  });

  it('passes the `parentId` prop down to the `WorkItemAddNote` component', async () => {
    createComponent({ parentId: 'example-id' });
    await waitForPromises();

    expect(findWorkItemAddNote().props('parentId')).toBe('example-id');
  });

  describe('when hideFullscreenMarkdownButton prop is true', () => {
    beforeEach(async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
        propsData: { hideFullscreenMarkdownButton: true },
      });
      await waitForPromises();
    });

    it('passes prop to work-item-add-note', () => {
      expect(findWorkItemAddNote().props('hideFullscreenMarkdownButton')).toBe(true);
    });
    it('passes prop to work-item-discussion', () => {
      expect(findAllWorkItemDiscussions().at(0).props('hideFullscreenMarkdownButton')).toBe(true);
    });
  });

  describe('r key (reply) shortcut', () => {
    const triggerReplyShortcut = async () => {
      Mousetrap.trigger(keysFor(ISSUABLE_COMMENT_OR_REPLY)[0]);
      await nextTick();
    };

    beforeEach(async () => {
      window.gon.current_user_id = 1;
      createComponent({
        defaultWorkItemNotesQueryHandler: jest
          .fn()
          .mockResolvedValue(mockWorkItemNotesResponseWithComments()),
        canCreateNote: true,
      });

      jest.spyOn(gfmEventHub, '$emit');
      jest.spyOn(wrapper.vm, 'appendText').mockImplementation(() => {});

      await waitForPromises();
    });

    it('emits `quote-reply` event on $root when reply quotes an existing discussion', async () => {
      jest.spyOn(CopyAsGFM, 'selectionToGfm').mockReturnValueOnce('foo');
      jest.spyOn(wrapper.vm, 'getDiscussionIdFromSelection').mockReturnValue('discussion-1');
      await triggerReplyShortcut();

      expect(gfmEventHub.$emit).toHaveBeenCalledWith('quote-reply', {
        discussionId: 'discussion-1',
        text: 'foo',
        event: expect.any(Object),
      });
    });

    it.each`
      sortDirection | description
      ${ASC}        | ${'oldest-first'}
      ${DESC}       | ${'newest-first'}
    `(
      'calls on appendText on work-item-add-note form with discussion sort direction set to $description',
      async ({ sortDirection }) => {
        jest.spyOn(CopyAsGFM, 'selectionToGfm').mockReturnValueOnce('foo');

        findActivityHeader().vm.$emit('changeSort', sortDirection);
        await nextTick();

        await triggerReplyShortcut();

        expect(gfmEventHub.$emit).not.toHaveBeenCalledWith();
        expect(wrapper.vm.appendText).toHaveBeenCalledWith('foo');
      },
    );
  });

  describe('up-arrow key (edit last note) shortcut', () => {
    const setupComponent = async ({
      notesResponse = mockWorkItemNotesResponseWithComments(),
    } = {}) => {
      window.gon.current_user_id = 1;

      jest.clearAllMocks();

      jest.spyOn(gfmEventHub, '$emit').mockImplementation(jest.fn());
      jest.spyOn(gfmEventHub, '$on').mockImplementation(jest.fn());

      createComponent({
        defaultWorkItemNotesQueryHandler: jest.fn().mockResolvedValue(notesResponse),
        canCreateNote: true,
      });

      await waitForPromises();
    };

    it('attaches `edit-current-user-last-note` event listener on mount', async () => {
      await setupComponent();

      expect(gfmEventHub.$on).toHaveBeenCalledWith(
        'edit-current-user-last-note',
        wrapper.vm.editCurrentUserLastNote,
      );
    });

    it('emits `edit-note` on markdown-editor event-hub with last user note', async () => {
      const mockLastNote =
        mockWorkItemNotesWidgetResponseWithComments.discussions.nodes[1].notes.nodes[0];
      await setupComponent();

      const registeredHandler = gfmEventHub.$on.mock.calls.find(
        (call) => call[0] === 'edit-current-user-last-note',
      )[1];

      const mockEvent = {
        target: wrapper.findComponent(WorkItemAddNote).element,
      };

      await registeredHandler(mockEvent);

      expect(gfmEventHub.$emit).toHaveBeenCalledWith('edit-note', {
        note: {
          ...mockLastNote,
        },
      });
    });

    it('does not emit `edit-note` on markdown-editor event-hub when no last user note is found', async () => {
      await setupComponent({
        notesResponse: mockWorkItemNotesByIidResponse,
      });

      const registeredHandler = gfmEventHub.$on.mock.calls.find(
        (call) => call[0] === 'edit-current-user-last-note',
      )[1];

      const mockEvent = {
        target: wrapper.findComponent(WorkItemAddNote).element,
      };

      await registeredHandler(mockEvent);

      expect(gfmEventHub.$emit).not.toHaveBeenCalledWith('edit-note');
    });
  });

  it('emits `focus` event when WorkItemAddNote emits `focus`', async () => {
    createComponent();
    await waitForPromises();

    findWorkItemAddNote().vm.$emit('focus');

    expect(wrapper.emitted('focus')).toHaveLength(1);
  });

  it('emits `blur` event when WorkItemAddNote emits `blur`', async () => {
    createComponent();
    await waitForPromises();

    findWorkItemAddNote().vm.$emit('blur');

    expect(wrapper.emitted('blur')).toHaveLength(1);
  });
});
