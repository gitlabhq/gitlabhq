import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NotePreview from '~/notes/components/note_preview.vue';
import NoteableNote from '~/notes/components/noteable_note.vue';
import noteQuery from '~/notes/graphql/note.query.graphql';

const noteQueryHandler = jest.fn().mockResolvedValue({
  data: {
    note: {
      id: 'gid://gitlab/Note/1',
      author: {
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        username: 'root',
        avatar_url: '',
        web_url: '',
        web_path: '',
      },
      body_html: 'my quick note',
      created_at: '2020-01-01T10:00:00.000Z',
      last_edited_at: null,
      last_edited_by: null,
      internal: false,
      url: '/note/1',
    },
  },
});

describe('Note preview', () => {
  let wrapper;

  Vue.use(VueApollo);

  const createComponent = ({ noteId = '1', queryHandlers = [[noteQuery, noteQueryHandler]] }) => {
    wrapper = shallowMount(NotePreview, {
      apolloProvider: createMockApollo(queryHandlers),
      propsData: {
        noteId,
      },
    });
  };

  const findNoteableNote = () => wrapper.findComponent(NoteableNote);

  it('does nothing if URL does not contain a note id', () => {
    createComponent({ noteId: null });

    expect(noteQueryHandler).not.toHaveBeenCalled();
    expect(wrapper.html()).toBe('');
  });

  it('does nothing if URL links to a system note', () => {
    createComponent({
      noteId: '50f036b11addf3c1dc3d4b43a96cfeb799ae2f7c',
    });

    expect(noteQueryHandler).not.toHaveBeenCalled();
    expect(wrapper.html()).toBe('');
  });

  it('renders a note', async () => {
    createComponent({ noteId: '1234' });

    await waitForPromises();

    expect(findNoteableNote().exists()).toBe(true);
    expect(findNoteableNote().props('showReplyButton')).toBe(false);
  });

  it('renders nothing if note returns null', async () => {
    createComponent({
      noteId: '1234',
      queryHandlers: [[noteQuery, jest.fn().mockResolvedValue({ data: { note: null } })]],
    });

    await waitForPromises();

    expect(wrapper.html()).toBe('');
  });
});
