import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import CommitTimeline from '~/rapid_diffs/app/discussions/timeline.vue';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/utils/secret_detection');

Vue.use(PiniaVuePlugin);

describe('CommitTimeline', () => {
  let pinia;
  let wrapper;
  let axiosMock;

  const createDiscussion = (overrides = {}) => ({
    id: 'discussion-1',
    notes: [{ id: 'note-1', body: 'Test note' }],
    isForm: false,
    ...overrides,
  });

  const defaultProvide = {
    userPermissions: { can_create_note: true },
    endpoints: { discussions: '/api/discussions' },
  };

  const findDiffDiscussions = () => wrapper.findComponent(DiffDiscussions);

  beforeEach(() => {
    pinia = createTestingPinia({ stubActions: false });
    axiosMock = new AxiosMockAdapter(axios);
    isLoggedIn.mockReturnValue(true);
    detectAndConfirmSensitiveTokens.mockResolvedValue(true);
  });

  const createComponent = (discussions = [], provide = {}) => {
    useDiffDiscussions(pinia).$patch({ discussions });

    wrapper = shallowMount(CommitTimeline, {
      pinia,
      provide: { ...defaultProvide, ...provide },
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
    it('adds discussion on successful save', async () => {
      const newDiscussion = { id: 'new-1', notes: [{ id: 'note-1' }] };
      axiosMock.onPost('/api/discussions').reply(HTTP_STATUS_OK, { discussion: newDiscussion });
      createComponent([createDiscussion()]);

      await wrapper.findComponent(NoteForm).props('saveNote')('test note');

      expect(useDiffDiscussions(pinia).discussions).toContainEqual(
        expect.objectContaining({ id: 'new-1' }),
      );
    });
  });
});
