import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import ImageDiffViewerWithDiscussions from '~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_viewer.vue';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import BaseImageDiffOverlay from '~/diffs/components/base_image_diff_overlay.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import axios from '~/lib/utils/axios_utils';
import { clearDraft } from '~/lib/utils/autosave';
import { createAlert } from '~/alert';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/lib/utils/autosave');
jest.mock('~/alert');

describe('ImageDiffViewerWithDiscussions', () => {
  let wrapper;
  let axiosMock;
  let pinia;

  const defaultProps = {
    imageData: {
      old_path: 'old.png',
      new_path: 'new.png',
      old_size: 1024,
      new_size: 2048,
      diff_mode: 'new',
    },
    oldPath: 'old.png',
    newPath: 'new.png',
  };

  const defaultProvide = {
    userPermissions: {
      can_create_note: true,
    },
    endpoints: {
      discussions: '/api/discussions',
      previewMarkdown: '/api/preview',
      markdownDocs: '/docs/markdown',
      register: '/register',
      signIn: '/sign_in',
      reportAbuse: '/report',
    },
  };

  const createImageDiscussion = (id, oldPath, newPath) => ({
    id,
    repliesExpanded: true,
    isReplying: false,
    hidden: false,
    notes: [
      {
        id: `note-${id}`,
        isEditing: false,
        editedNote: null,
        position: {
          position_type: 'image',
          old_path: oldPath,
          new_path: newPath,
          x: 10,
          y: 20,
          width: 100,
          height: 200,
        },
      },
    ],
  });

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMount(ImageDiffViewerWithDiscussions, {
      pinia,
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        ImageViewer: stubComponent(ImageViewer, {
          template: `<div><slot name="image-overlay" :width="100" :height="200" :rendered-width="100" :rendered-height="200"></slot></div>`,
        }),
      },
    });
  };

  const findImageViewer = () => wrapper.findComponent(ImageViewer);
  const findDiffDiscussions = () => wrapper.findComponent(DiffDiscussions);
  const findOverlay = () => wrapper.findComponent(BaseImageDiffOverlay);
  const findNoteForm = () => wrapper.findComponent(NoteForm);

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    pinia = createTestingPinia({ stubActions: false });
    useDiffDiscussions();
  });

  describe('image view', () => {
    it('renders ImageViewer with image data', () => {
      createComponent();
      expect(findImageViewer().props('imageData')).toMatchObject(defaultProps.imageData);
    });

    it('passes props overlay', () => {
      useDiffDiscussions().discussions = [createImageDiscussion('1', 'old.png', 'new.png')];
      createComponent();

      const overlay = findOverlay();
      expect(overlay.props()).toMatchObject({
        discussions: [expect.objectContaining({ id: '1' })],
        canComment: true,
        width: 100,
        height: 200,
        renderedWidth: 100,
        renderedHeight: 200,
      });
    });

    it('respects user permissions for commenting', () => {
      createComponent(undefined, { userPermissions: { can_create_note: false } });
      expect(findOverlay().props('canComment')).toBe(false);
    });
  });

  describe('discussions', () => {
    it('renders DiffDiscussions with discussions from store', () => {
      useDiffDiscussions().discussions = [
        createImageDiscussion('1', 'old.png', 'new.png'),
        createImageDiscussion('2', 'old.png', 'new.png'),
      ];
      createComponent();

      expect(findDiffDiscussions().props('discussions')).toHaveLength(2);
      expect(findDiffDiscussions().props('counterBadgeVisible')).toBe(true);
    });

    it('filters discussions by path', () => {
      useDiffDiscussions().discussions = [
        createImageDiscussion('1', 'other.png', 'other.png'),
        createImageDiscussion('2', 'old.png', 'new.png'),
      ];
      createComponent();

      expect(findDiffDiscussions().props('discussions')).toHaveLength(1);
      expect(findDiffDiscussions().props('discussions')[0].id).toBe('2');
    });
  });

  describe('comment form', () => {
    const formData = { x: 10, y: 20, width: 100, height: 200 };

    it('is hidden by default', () => {
      createComponent();
      expect(findNoteForm().exists()).toBe(false);
    });

    it('opens form when overlay emits image-click', async () => {
      createComponent();
      findOverlay().vm.$emit('image-click', formData);
      await nextTick();

      expect(findNoteForm().exists()).toBe(true);
    });

    it('preserves noteBody when reopening form at different position', async () => {
      createComponent();
      findOverlay().vm.$emit('image-click', formData);
      await nextTick();

      findNoteForm().vm.$emit('input', 'draft text');
      await nextTick();

      findOverlay().vm.$emit('image-click', { x: 50, y: 60, width: 100, height: 200 });
      await nextTick();

      expect(findNoteForm().props('noteBody')).toBe('draft text');
    });

    it('closes form when NoteForm emits cancel', async () => {
      createComponent();
      findOverlay().vm.$emit('image-click', formData);
      await nextTick();

      findNoteForm().vm.$emit('cancel');
      await nextTick();

      expect(findNoteForm().exists()).toBe(false);
    });

    it('generates correct autosave key', async () => {
      createComponent({ oldPath: 'images/old.png', newPath: 'images/new.png' });
      findOverlay().vm.$emit('image-click', formData);
      await nextTick();

      expect(findNoteForm().props('autosaveKey')).toBe(
        `${window.location.pathname}-image-images/old.png-images/new.png`,
      );
    });

    it('does not render NoteForm when commentForm is null', () => {
      createComponent();
      expect(findNoteForm().exists()).toBe(false);
    });

    describe('saving notes', () => {
      const mockDiscussion = {
        id: 'new-discussion',
        notes: [
          {
            id: 'new-note',
            position: {
              position_type: 'image',
              old_path: 'old.png',
              new_path: 'new.png',
            },
          },
        ],
      };

      describe('on success', () => {
        beforeEach(() => {
          axiosMock
            .onPost(defaultProvide.endpoints.discussions)
            .reply(HTTP_STATUS_OK, { discussion: mockDiscussion });
        });

        it('posts note with correct position data', async () => {
          createComponent();
          findOverlay().vm.$emit('image-click', formData);
          await nextTick();

          await findNoteForm().props('saveNote')('My comment');

          const requestData = JSON.parse(axiosMock.history.post[0].data);
          expect(requestData).toEqual({
            note: {
              position: {
                old_path: 'old.png',
                new_path: 'new.png',
                position_type: 'image',
                width: 100,
                height: 200,
                x: 10,
                y: 20,
              },
              note: 'My comment',
            },
          });
        });

        it('adds discussion to store and closes form', async () => {
          createComponent();
          const store = useDiffDiscussions();
          findOverlay().vm.$emit('image-click', formData);
          await nextTick();

          await findNoteForm().props('saveNote')('My comment');

          expect(store.discussions).toHaveLength(1);
          expect(store.discussions[0].id).toBe('new-discussion');
          expect(findNoteForm().exists()).toBe(false);
        });

        it('clears draft on successful save', async () => {
          createComponent();
          findOverlay().vm.$emit('image-click', formData);
          await nextTick();

          await findNoteForm().props('saveNote')('My comment');

          expect(clearDraft).toHaveBeenCalled();
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          axiosMock
            .onPost(defaultProvide.endpoints.discussions)
            .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        });

        it('shows alert on save failure', async () => {
          createComponent();
          findOverlay().vm.$emit('image-click', formData);
          await nextTick();

          await findNoteForm().props('saveNote')('My comment');

          expect(createAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              message: 'Failed to submit your comment. Please try again.',
            }),
          );
        });

        it('keeps form open on save failure', async () => {
          createComponent();
          findOverlay().vm.$emit('image-click', formData);
          await nextTick();

          await findNoteForm().props('saveNote')('My comment');

          expect(findNoteForm().exists()).toBe(true);
        });
      });
    });
  });
});
