import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import DiffFileDiscussions from '~/rapid_diffs/app/discussions/diff_file_discussions.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiscussions } from '~/notes/store/discussions';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';

describe('DiffFileDiscussions', () => {
  let wrapper;
  let store;
  let mock;

  const oldPath = 'file.js';
  const newPath = 'file.js';
  const discussionsEndpoint = '/discussions';

  const fileDiscussion = {
    id: 'file-disc-1',
    diff_discussion: true,
    position: {
      old_path: oldPath,
      new_path: newPath,
      position_type: 'file',
      old_line: null,
      new_line: null,
    },
    notes: [{ id: 'note-1', author: { id: 1 }, created_at: new Date().toISOString() }],
  };

  const createComponent = () => {
    wrapper = shallowMount(DiffFileDiscussions, {
      propsData: { oldPath, newPath },
      provide: {
        store,
        userPermissions: { can_create_note: true },
        endpoints: { discussions: discussionsEndpoint },
      },
    });
  };

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useDiffDiscussions();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('renders existing discussions', () => {
    store.setInitialDiscussions([fileDiscussion]);
    createComponent();
    const discussions = wrapper.findComponent(DiffDiscussions).props('discussions');
    expect(discussions).toHaveLength(1);
    expect(discussions[0].id).toBe('file-disc-1');
  });

  it('renders NoteForm when a file discussion form exists', () => {
    store.addNewFileDiscussionForm({ oldPath, newPath });
    createComponent();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
  });

  it('emits empty when discussions become empty', async () => {
    store.addNewFileDiscussionForm({ oldPath, newPath });
    createComponent();
    store.removeNewFileDiscussionForm(store.discussionForms[0]);
    await nextTick();
    expect(wrapper.emitted('empty')).toStrictEqual([[]]);
  });

  it('saves a note and replaces form with discussion', async () => {
    const responseDiscussion = {
      id: 'new-disc',
      diff_discussion: true,
      position: fileDiscussion.position,
      notes: [{ id: 'new-note' }],
    };
    mock.onPost(discussionsEndpoint).reply(HTTP_STATUS_OK, { discussion: responseDiscussion });

    store.addNewFileDiscussionForm({ oldPath, newPath });
    createComponent();
    await wrapper.findComponent(NoteForm).props('saveNote')('my comment');
    await nextTick();

    expect(store.discussionForms).toHaveLength(0);
    expect(useDiscussions().discussions).toHaveLength(1);
    expect(useDiscussions().discussions[0].id).toBe('new-disc');
  });
});
