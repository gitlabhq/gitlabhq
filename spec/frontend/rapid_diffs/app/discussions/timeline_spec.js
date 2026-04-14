import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { createAlert } from '~/alert';
import { COMMENT_FORM } from '~/notes/i18n';
import CommitTimeline from '~/rapid_diffs/app/discussions/timeline.vue';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import { useCommitDiffDiscussions } from '~/rapid_diffs/stores/commit_discussions_store';
import { useDiscussions } from '~/notes/store/discussions';

jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/secret_detection');

Vue.use(PiniaVuePlugin);

describe('CommitTimeline', () => {
  let pinia;
  let wrapper;

  const createDiscussion = (overrides = {}) => ({
    id: 'discussion-1',
    notes: [{ id: 'note-1', body: 'Test note' }],
    isForm: false,
    ...overrides,
  });

  let store;

  const defaultProvide = {
    userPermissions: { can_create_note: true },
    endpoints: { discussions: '/api/discussions' },
  };

  const findDiffDiscussions = () => wrapper.findComponent(DiffDiscussions);

  beforeEach(() => {
    pinia = createTestingPinia({ stubActions: false });
    store = useCommitDiffDiscussions(pinia);
    store.createNewDiscussion = jest.fn().mockResolvedValue();
    isLoggedIn.mockReturnValue(true);
    detectAndConfirmSensitiveTokens.mockResolvedValue(true);
  });

  const createComponent = (discussions = [], provide = {}) => {
    useDiscussions(pinia).discussions = discussions;

    wrapper = shallowMount(CommitTimeline, {
      pinia,
      provide: { store, ...defaultProvide, ...provide },
    });
  };

  it('renders filtered discussions', () => {
    const regularDiscussion = createDiscussion({ id: 'regular-1' });
    const formDiscussion = createDiscussion({ id: 'form-1', isForm: true });
    createComponent([regularDiscussion, formDiscussion]);

    expect(findDiffDiscussions().props('discussions')).toEqual([regularDiscussion]);
  });

  it('passes timeline-layout prop to DiffDiscussions', () => {
    createComponent([createDiscussion()]);
    expect(findDiffDiscussions().props('timelineLayout')).toBe(true);
  });

  describe('saveNote', () => {
    it('calls store.createNewDiscussion on successful save', async () => {
      createComponent([createDiscussion()]);

      await wrapper.findComponent(NoteForm).props('saveNote')('test note');

      expect(store.createNewDiscussion).toHaveBeenCalledWith({ note: 'test note' });
    });

    it('shows alert when save fails', async () => {
      store.createNewDiscussion.mockRejectedValue(new Error('fail'));
      createComponent([createDiscussion()]);

      await wrapper.findComponent(NoteForm).props('saveNote')('test note');

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK,
        }),
      );
    });
  });
});
