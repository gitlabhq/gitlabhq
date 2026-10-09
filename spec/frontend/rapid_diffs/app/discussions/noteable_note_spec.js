import { merge } from 'lodash-es';
import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NoteableNote from '~/rapid_diffs/app/discussions/noteable_note.vue';
import NoteHeader from '~/rapid_diffs/app/discussions/note_header.vue';
import NoteActions from '~/rapid_diffs/app/discussions/note_actions.vue';
import NoteBody from '~/rapid_diffs/app/discussions/note_body.vue';
import TimelineEntryItem from '~/rapid_diffs/app/discussions/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';

import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/alert');
jest.mock('~/lib/utils/secret_detection');

describe('NoteableNote', () => {
  let wrapper;
  let defaultProps;
  let store;

  const defaultProvisions = {
    endpoints: {
      reportAbuse: '/report-abuse',
    },
  };

  const createNote = (customOptions) => {
    return merge(
      {
        id: '1',
        author: {
          id: 100,
          name: 'name',
          path: 'path',
          username: 'username',
          avatar_url: 'avatar_url',
        },
        current_user: {
          can_award_emoji: true,
          can_edit: true,
        },
        internal: false,
        imported: false,
        is_contributor: true,
        is_noteable_author: true,
        created_at: '2025-08-25T05:03:12.757Z',
        noteable_note_url: '/noteable_note_url',
        human_access: 'Developer',
        project_name: 'project_name',
        noteable_type: 'Commit',
        path: '/note/path',
        noteable_id: 123,
        isEditing: false,
        toggle_award_path: '/award',
      },
      customOptions,
    );
  };

  const createComponent = (props = {}, provide = defaultProvisions) => {
    wrapper = shallowMount(NoteableNote, {
      propsData: merge(defaultProps, props),
      provide: { store, ...provide },
      stubs: {
        GlSprintf: {
          template: '<span><slot name="timeago" /><slot name="author" /></span>',
        },
        NoteSessionBar: {
          name: 'NoteSessionBar',
          props: ['agentName', 'sessionId', 'status', 'isReply'],
          template: '<div />',
        },
        NoteAgentActorLine: {
          name: 'NoteAgentActorLine',
          props: {
            presence: { type: Object, required: true },
          },
          template: '<div />',
        },
      },
    });
  };

  beforeEach(() => {
    defaultProps = {
      note: createNote(),
    };
    store = {
      saveNote: jest.fn().mockResolvedValue(),
      destroyNote: jest.fn().mockResolvedValue(),
      deleteNote: jest.fn(),
      toggleAwardOnNote: jest.fn().mockResolvedValue(),
    };
    confirmAction.mockResolvedValue(true);
    detectAndConfirmSensitiveTokens.mockResolvedValue(true);
  });

  afterEach(() => {
    confirmAction.mockClear();
    createAlert.mockClear();
    detectAndConfirmSensitiveTokens.mockClear();
  });

  const findNoteActions = () => wrapper.findComponent(NoteActions);
  const findNoteBody = () => wrapper.findComponent(NoteBody);
  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);
  const findNoteSessionBar = () => wrapper.findComponent({ name: 'NoteSessionBar' });
  const findNoteHeader = () => wrapper.findComponent(NoteHeader);
  const findAgentActorLine = () => wrapper.findComponent({ name: 'NoteAgentActorLine' });

  it('shows note header with correct props', () => {
    createComponent();
    expect(wrapper.findComponent(NoteHeader).props()).toMatchObject({
      author: defaultProps.note.author,
      createdAt: defaultProps.note.created_at,
      noteId: defaultProps.note.id,
      isInternalNote: defaultProps.note.internal,
      isImported: defaultProps.note.imported,
    });
  });

  it('shows note actions with correct props', () => {
    createComponent({ showReplyButton: true });
    expect(findNoteActions().props()).toMatchObject({
      authorId: defaultProps.note.author.id,
      noteUrl: defaultProps.note.noteable_note_url,
      accessLevel: defaultProps.note.human_access,
      isContributor: defaultProps.note.is_contributor,
      isAuthor: defaultProps.note.is_noteable_author,
      projectName: defaultProps.note.project_name,
      noteableType: defaultProps.note.noteable_type,
      showReply: true,
      canEdit: defaultProps.note.current_user.can_edit,
      canAwardEmoji: defaultProps.note.current_user.can_award_emoji,
      canDelete: defaultProps.note.current_user.can_edit,
      canReportAsAbuse: true,
    });
  });

  describe('when the note is linked to a Duo Agent Platform session', () => {
    it('passes the session id to the note actions', () => {
      createComponent({ note: createNote({ duo_session_id: 42 }) });

      expect(findNoteActions().props('duoSessionId')).toBe(42);
    });
  });

  it('shows note body with correct props', () => {
    createComponent({ autosaveKey: 'autosave-key', restoreFromAutosave: true, isFirstNote: true });
    expect(findNoteBody().props()).toMatchObject({
      note: defaultProps.note,
      canEdit: defaultProps.note.current_user.can_edit,
      isEditing: defaultProps.note.isEditing,
      autosaveKey: 'autosave-key',
      restoreFromAutosave: true,
      isFirstNote: true,
    });
  });

  it('propagates note edited event', () => {
    createComponent();
    findNoteBody().vm.$emit('input', 'edit');
    expect(wrapper.emitted('note-edited')).toStrictEqual([['edit']]);
  });

  describe('TimelineEntryItem', () => {
    it.each`
      prop                  | value        | expected
      ${'timelineLayout'}   | ${true}      | ${true}
      ${'isLastDiscussion'} | ${true}      | ${true}
      ${'timelineLayout'}   | ${undefined} | ${false}
      ${'isLastDiscussion'} | ${undefined} | ${false}
    `('passes $prop as $expected when set to $value', ({ prop, value, expected }) => {
      createComponent(value !== undefined ? { [prop]: value } : {});
      expect(findTimelineEntryItem().props(prop)).toBe(expected);
    });
  });

  describe('note deletion', () => {
    const triggerDelete = () => {
      createComponent({ note: createNote() });
      findNoteActions().vm.$emit('delete');
    };

    it('shows confirmation modal', () => {
      triggerDelete();
      expect(confirmAction).toHaveBeenCalledWith(
        'Are you sure you want to delete this comment?',
        expect.objectContaining({ primaryBtnText: 'Delete comment' }),
      );
    });

    describe('when confirmed', () => {
      beforeEach(triggerDelete);

      it('calls store.destroyNote', async () => {
        await waitForPromises();
        expect(store.destroyNote).toHaveBeenCalledWith(defaultProps.note);
      });
    });

    describe('when confirmation is cancelled', () => {
      beforeEach(() => {
        confirmAction.mockResolvedValueOnce(false);
        triggerDelete();
      });

      it('does not call destroyNote', async () => {
        await waitForPromises();
        expect(store.destroyNote).not.toHaveBeenCalled();
      });
    });

    describe('when deletion fails', () => {
      beforeEach(() => {
        store.destroyNote.mockRejectedValue(new Error('fail'));
        triggerDelete();
      });

      it('creates alert', async () => {
        await waitForPromises();
        expect(createAlert).toHaveBeenCalled();
      });
    });
  });

  describe('note editing/saving via NoteBody', () => {
    const noteText = 'updated note content';

    describe('when editing', () => {
      it('scrolls element into view', async () => {
        const spy = jest.spyOn(Element.prototype, 'scrollIntoView');
        createComponent({ note: createNote({ isEditing: true }) });
        await nextTick();
        expect(spy).toHaveBeenCalledWith({ block: 'nearest' });
      });
    });

    it('calls store.saveNote and emits cancel-editing on success', async () => {
      const note = createNote({ isEditing: true });
      createComponent({ note });
      await findNoteBody().props('saveNote')(noteText);

      expect(detectAndConfirmSensitiveTokens).toHaveBeenCalledWith({ content: noteText });
      expect(store.saveNote).toHaveBeenCalledWith(note, noteText);
      expect(wrapper.emitted('cancel-editing')).toStrictEqual([[]]);
    });

    it('propagates API failure to the form', async () => {
      store.saveNote.mockRejectedValue(new Error('fail'));

      createComponent({ note: createNote({ isEditing: true }) });

      await expect(findNoteBody().props('saveNote')(noteText)).rejects.toThrow('fail');
      expect(wrapper.emitted('cancel-editing')).toBe(undefined);
    });
  });

  describe('cancel editing via NoteBody', () => {
    const setupEditing = () => {
      createComponent({ note: createNote({ isEditing: true }) });
    };

    describe('when confirmation is not needed', () => {
      beforeEach(async () => {
        setupEditing();
        findNoteBody().vm.$emit('cancel-editing', false);
        await nextTick();
      });

      it('emits cancel-editing', () => {
        expect(wrapper.emitted('cancel-editing')).toStrictEqual([[]]);
      });
    });

    describe('when confirmation is needed', () => {
      it('shows confirmation modal', () => {
        setupEditing();
        findNoteBody().vm.$emit('cancel-editing', true);
        expect(confirmAction).toHaveBeenCalledWith(
          'Are you sure you want to cancel editing this comment?',
          expect.objectContaining({ primaryBtnText: 'Cancel editing' }),
        );
      });

      describe('when confirmed', () => {
        beforeEach(() => {
          setupEditing();
          findNoteBody().vm.$emit('cancel-editing', true);
        });

        it('emits cancel-editing', async () => {
          await waitForPromises();
          expect(wrapper.emitted('cancel-editing')).toStrictEqual([[]]);
        });
      });

      describe('when denied', () => {
        beforeEach(() => {
          confirmAction.mockResolvedValueOnce(false);
          setupEditing();
          findNoteBody().vm.$emit('cancel-editing', true);
        });

        it('does not emit cancel-editing', async () => {
          await waitForPromises();
          expect(wrapper.emitted('cancel-editing')).toBeUndefined();
        });
      });
    });
  });

  it('handles award event on note body', async () => {
    const note = createNote();
    const award = 'smile';
    createComponent({ note });
    await wrapper.findComponent(NoteBody).vm.$emit('award', award);
    await waitForPromises();
    expect(store.toggleAwardOnNote).toHaveBeenCalledWith(note, award);
  });

  it('handles award event on note actions', async () => {
    const note = createNote();
    const award = 'smile';
    createComponent({ note });
    await wrapper.findComponent(NoteActions).vm.$emit('award', award);
    await waitForPromises();
    expect(store.toggleAwardOnNote).toHaveBeenCalledWith(note, award);
  });

  describe('resolved note', () => {
    const resolvedBy = {
      id: 200,
      name: 'Jane Doe',
      path: '/jane_doe',
    };
    const resolvedAt = '2025-09-01T10:00:00.000Z';

    const createResolvedNote = (overrides = {}) =>
      createNote({ resolved_at: resolvedAt, resolved_by: resolvedBy, ...overrides });

    describe('when isResolved is false', () => {
      beforeEach(() => {
        createComponent({ note: createResolvedNote(), isResolved: false });
      });

      it('does not show resolved section', () => {
        expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
      });
    });

    describe('when isResolved is true', () => {
      beforeEach(() => {
        createComponent({ note: createResolvedNote(), isResolved: true });
      });

      it('shows resolved section', () => {
        expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
      });

      it('passes resolved_at to TimeAgoTooltip', () => {
        expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(resolvedAt);
      });

      it('links to the resolver via GlLink', () => {
        const link = wrapper.findComponent(GlLink);
        expect(link.attributes('href')).toBe(resolvedBy.path);
        expect(link.text()).toBe(resolvedBy.name);
      });
    });

    describe('when not resolved by push', () => {
      beforeEach(() => {
        createComponent({
          note: createResolvedNote({ resolved_by_push: false }),
          isResolved: true,
        });
      });

      it('uses "Resolved" text', () => {
        expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
          'Resolved %{timeago} by %{author}',
        );
      });
    });

    describe('when resolved by push', () => {
      beforeEach(() => {
        createComponent({ note: createResolvedNote({ resolved_by_push: true }), isResolved: true });
      });

      it('uses "Automatically resolved" text', () => {
        expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
          'Automatically resolved %{timeago} by %{author}',
        );
      });
    });
  });

  describe('draft notes', () => {
    beforeEach(() => {
      createComponent({ note: createNote({ isDraft: true }) });
    });

    it('disables award emoji', () => {
      expect(findNoteActions().props('canAwardEmoji')).toBe(false);
    });

    it('disables report as abuse', () => {
      expect(findNoteActions().props('canReportAsAbuse')).toBe(false);
    });
  });

  describe('NoteSessionBar', () => {
    const SESSION_ID = 42;
    const AGENT_NAME = 'Duo';

    const sessionNote = createNote({
      duo_session_id_triggered: SESSION_ID,
      duo_session_agent_name: AGENT_NAME,
      duo_session_status: 'running',
    });

    describe('when noteAgentSessionBar feature flag is disabled', () => {
      beforeEach(() => {
        createComponent(
          { note: sessionNote },
          { ...defaultProvisions, glFeatures: { noteAgentSessionBar: false } },
        );
      });

      it('does not render', () => {
        expect(findNoteSessionBar().exists()).toBe(false);
      });
    });

    describe('when noteAgentSessionBar feature flag is enabled', () => {
      const createSessionComponent = (props = {}) =>
        createComponent(
          { note: sessionNote, ...props },
          { ...defaultProvisions, glFeatures: { noteAgentSessionBar: true } },
        );

      describe('when duo_session_id_triggered is absent', () => {
        beforeEach(() => {
          createSessionComponent({ note: { ...sessionNote, duo_session_id_triggered: null } });
        });

        it('does not render', () => {
          expect(findNoteSessionBar().exists()).toBe(false);
        });
      });

      describe('when duo_session_agent_name is absent', () => {
        beforeEach(() => {
          createSessionComponent({ note: { ...sessionNote, duo_session_agent_name: null } });
        });

        it('does not render', () => {
          expect(findNoteSessionBar().exists()).toBe(false);
        });
      });

      describe('when session fields are present', () => {
        beforeEach(() => {
          createSessionComponent();
        });

        it('renders', () => {
          expect(findNoteSessionBar().exists()).toBe(true);
        });

        it('passes correct props', () => {
          expect(findNoteSessionBar().props()).toMatchObject({
            agentName: AGENT_NAME,
            sessionId: SESSION_ID,
            status: 'running',
          });
        });
      });

      describe('when status is finished', () => {
        beforeEach(() => {
          createSessionComponent({ note: { ...sessionNote, duo_session_status: 'finished' } });
        });

        it('renders (NoteSessionBar handles its own visibility)', () => {
          expect(findNoteSessionBar().exists()).toBe(true);
        });
      });

      describe('when isFirstNote is true', () => {
        beforeEach(() => {
          createSessionComponent({ isFirstNote: true });
        });

        it('passes isReply as false', () => {
          expect(findNoteSessionBar().props('isReply')).toBe(false);
        });
      });

      describe('when isFirstNote is false', () => {
        beforeEach(() => {
          createSessionComponent({ isFirstNote: false });
        });

        it('passes isReply as true', () => {
          expect(findNoteSessionBar().props('isReply')).toBe(true);
        });
      });
    });
  });

  describe('AgentActorLine', () => {
    const agentPresence = {
      session_id: 'gid://gitlab/Ai::DuoWorkflows::Workflow/42',
      agent_name: 'Developer Agent',
      agent_catalog_web_path: '/-/ai/catalog/agents/3',
      initiator_type: 'USER',
      initiator: { label: '@nokafor', web_path: '/nokafor' },
      user_permissions: { read_duo_workflow: true },
    };

    const createWithFlag = ({
      noteOptions = { agent_presence: agentPresence },
      flag = true,
    } = {}) =>
      createComponent(
        { note: createNote({ duo_session_id: 42, ...noteOptions }) },
        { ...defaultProvisions, glFeatures: { agentPresenceConsolidation: flag } },
      );

    describe('when the agentPresenceConsolidation feature flag is disabled', () => {
      beforeEach(() => createWithFlag({ flag: false }));

      it('does not render the actor line', () => {
        expect(findAgentActorLine().exists()).toBe(false);
      });

      it('still offers the standalone session button', () => {
        expect(findNoteActions().props('duoSessionId')).toBe(42);
      });
    });

    describe.each`
      description                       | noteOptions
      ${'has no agent presence'}        | ${{}}
      ${'has a null agent presence'}    | ${{ agent_presence: null }}
      ${'has no resolvable agent name'} | ${{ agent_presence: { ...agentPresence, agent_name: null } }}
      ${'has no session to open'}       | ${{ agent_presence: { ...agentPresence, session_id: null } }}
    `('when the note $description', ({ noteOptions }) => {
      beforeEach(() => createWithFlag({ noteOptions }));

      it('does not render the actor line', () => {
        expect(findAgentActorLine().exists()).toBe(false);
      });

      it('keeps the standalone session button', () => {
        expect(findNoteActions().props('duoSessionId')).toBe(42);
      });
    });

    describe('when the note has agent presence', () => {
      beforeEach(() => createWithFlag());

      it('renders the actor line for the agent and its session', () => {
        expect(findAgentActorLine().props('presence')).toEqual({
          sessionId: 'gid://gitlab/Ai::DuoWorkflows::Workflow/42',
          agentName: 'Developer Agent',
          agentCatalogWebPath: '/-/ai/catalog/agents/3',
          initiatorType: 'USER',
          initiator: { label: '@nokafor', webPath: '/nokafor' },
          userPermissions: { readDuoWorkflow: true },
        });
      });

      it('hides the raw service account username, which the actor line replaces', () => {
        expect(findNoteHeader().props('hideUsername')).toBe(true);
      });

      it('keeps the header on one row', () => {
        expect(findNoteHeader().props('singleLine')).toBe(true);
      });

      it('drops the standalone session button, which would duplicate the session link', () => {
        expect(findNoteActions().props('duoSessionId')).toBe(null);
      });

      describe('when the actor line reports it no longer fits', () => {
        beforeEach(async () => {
          findAgentActorLine().vm.$emit('overflow', true);
          await nextTick();
        });

        it('lets the header wrap', () => {
          expect(findNoteHeader().props('singleLine')).toBe(false);
        });
      });
    });

    describe('when the current user cannot read the session', () => {
      beforeEach(() =>
        createWithFlag({
          noteOptions: {
            agent_presence: { ...agentPresence, user_permissions: { read_duo_workflow: false } },
          },
        }),
      );

      it('tells the actor line the session cannot be opened', () => {
        expect(findAgentActorLine().props('presence').userPermissions).toEqual({
          readDuoWorkflow: false,
        });
      });
    });

    describe('when the agent has no catalog profile', () => {
      beforeEach(() =>
        createWithFlag({
          noteOptions: { agent_presence: { ...agentPresence, agent_catalog_web_path: null } },
        }),
      );

      it('passes no catalog path', () => {
        expect(findAgentActorLine().props('presence').agentCatalogWebPath).toBe(null);
      });
    });
  });
});
