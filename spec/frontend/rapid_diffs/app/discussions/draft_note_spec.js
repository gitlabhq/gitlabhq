import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import DraftNote from '~/rapid_diffs/app/discussions/draft_note.vue';
import NoteHeader from '~/rapid_diffs/app/discussions/note_header.vue';
import NoteBody from '~/rapid_diffs/app/discussions/note_body.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/alert');

describe('DraftNote', () => {
  let wrapper;
  let store;

  const createDraft = (overrides = {}) => ({
    id: 1,
    author: { id: 100, name: 'Author', avatar_url: '/avatar' },
    created_at: '2025-01-01T00:00:00Z',
    current_user: { can_edit: true },
    isEditing: false,
    ...overrides,
  });

  const createComponent = (draft = createDraft()) => {
    wrapper = shallowMount(DraftNote, {
      propsData: { draft },
      provide: { store, endpoints: {} },
    });
  };

  beforeEach(() => {
    store = {
      deleteDraft: jest.fn().mockResolvedValue(),
      updateDraft: jest.fn().mockResolvedValue(),
      setEditingMode: jest.fn(),
    };
    confirmAction.mockResolvedValue(true);
  });

  afterEach(() => {
    confirmAction.mockClear();
    createAlert.mockClear();
  });

  it('renders note header with correct props', () => {
    const draft = createDraft();
    createComponent(draft);
    expect(wrapper.findComponent(NoteHeader).props()).toMatchObject({
      author: draft.author,
      createdAt: draft.created_at,
      showAvatar: true,
    });
  });

  it('renders pending badge in note header slot', () => {
    createComponent();
    expect(wrapper.find('[data-testid="draft-note-indicator"]').text()).toBe('Pending');
  });

  it('renders note body', () => {
    const draft = createDraft();
    createComponent(draft);
    expect(wrapper.findComponent(NoteBody).props()).toMatchObject({
      note: draft,
      isEditing: false,
    });
  });

  it('shows edit and delete buttons', () => {
    createComponent();
    const buttons = wrapper.findAllComponents(GlButton);
    expect(buttons).toHaveLength(2);
    expect(buttons.at(0).attributes('aria-label')).toBe('Edit comment');
    expect(buttons.at(1).attributes('aria-label')).toBe('Delete comment');
  });

  describe('deletion', () => {
    it('confirms and deletes draft', async () => {
      createComponent();
      wrapper.findAllComponents(GlButton).at(1).vm.$emit('click');
      await waitForPromises();

      expect(confirmAction).toHaveBeenCalledWith(
        'Are you sure you want to delete this comment?',
        expect.objectContaining({ primaryBtnText: 'Delete comment' }),
      );
      expect(store.deleteDraft).toHaveBeenCalledWith(expect.objectContaining({ id: 1 }));
    });

    it('does not delete when confirmation is cancelled', async () => {
      confirmAction.mockResolvedValueOnce(false);
      createComponent();
      wrapper.findAllComponents(GlButton).at(1).vm.$emit('click');
      await waitForPromises();

      expect(store.deleteDraft).not.toHaveBeenCalled();
    });

    it('shows alert on deletion failure', async () => {
      store.deleteDraft.mockRejectedValue(new Error('fail'));
      createComponent();
      wrapper.findAllComponents(GlButton).at(1).vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('editing', () => {
    it('calls store.setEditingMode on edit button click', () => {
      const draft = createDraft();
      createComponent(draft);
      wrapper.findAllComponents(GlButton).at(0).vm.$emit('click');
      expect(store.setEditingMode).toHaveBeenCalledWith(draft, true);
    });

    it('saves note and exits editing mode', async () => {
      const draft = createDraft({ isEditing: true });
      createComponent(draft);
      await wrapper.findComponent(NoteBody).props('saveNote')('updated text');

      expect(store.updateDraft).toHaveBeenCalledWith({ note: draft, noteText: 'updated text' });
      expect(store.setEditingMode).toHaveBeenCalledWith(draft, false);
    });

    it('shows alert on save failure', async () => {
      store.updateDraft.mockRejectedValue(new Error('fail'));
      createComponent(createDraft({ isEditing: true }));
      await wrapper.findComponent(NoteBody).props('saveNote')('text');

      expect(createAlert).toHaveBeenCalled();
    });

    it('cancels editing via store', () => {
      const draft = createDraft({ isEditing: true });
      createComponent(draft);
      wrapper.findComponent(NoteBody).vm.$emit('cancelEditing');
      expect(store.setEditingMode).toHaveBeenCalledWith(draft, false);
    });
  });
});
