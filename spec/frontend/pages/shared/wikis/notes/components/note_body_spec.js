import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteEditedText from '~/notes/components/note_edited_text.vue';
import WikiCommentForm from '~/pages/shared/wikis/wiki_notes/components/wiki_comment_form.vue';
import NoteBody from '~/pages/shared/wikis/wiki_notes/components/note_body.vue';
import { wikiCommentFormProvideData, note, noteableId } from '../mock_data';

describe('NoteBody', () => {
  let wrapper;

  const createWrapper = (propsData) =>
    shallowMountExtended(NoteBody, {
      propsData: {
        note,
        noteableId,
        ...propsData,
      },
      provide: wikiCommentFormProvideData,
      stubs: {
        WikiCommentForm,
      },
    });

  describe('renders correctly', () => {
    describe('when is editing is false', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should render note content correctly', async () => {
        const content = await wrapper.findByTestId('wiki-note-content').text();

        expect(content).toBe('an example note');
      });

      it('should not render "Edited" text when lastEdited is the same as createdAt', () => {
        const editedComponent = wrapper.findComponent(NoteEditedText);

        expect(editedComponent.exists()).toBe(false);
      });

      it('should render "Edited" text when lastEditedAt is not the same as createdAt', () => {
        // remounting to trigger mounted function
        wrapper = createWrapper({
          note: { ...note, lastEditedAt: '2024-11-11T08:11:34Z' },
          noteableId,
        });

        const editedComponent = wrapper.findComponent(NoteEditedText);
        expect(editedComponent.exists()).toBe(true);
      });
    });

    describe('when is editing is true', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should render note content in wiki comment form if hasDrafts is false', async () => {
        await wrapper.setProps({ isEditing: true });
        await nextTick();

        const wikiCommentForm = wrapper.findComponent(WikiCommentForm);
        await nextTick();

        expect(wikiCommentForm.vm.$refs.markdownEditor.value).toBe('an example note');
      });

      it('should not render note content in wiki comment form if hasDrafts is true', async () => {
        // making sure this component is not setting the content of the wiki comment form if there is a draft
        Object.defineProperty(wrapper.vm, 'hasDraft', {
          get() {
            return true;
          },
        });

        wrapper.setProps({ isEditing: true });
        await nextTick();

        const wikiCommentForm = wrapper.findComponent(WikiCommentForm);
        await nextTick();

        expect(wikiCommentForm.vm.$refs.markdownEditor.value).toBe('');
      });
    });
  });

  describe('comment form', () => {
    beforeEach(() => {
      wrapper = createWrapper({ isEditing: true });
    });

    it('should emit "cancel:edit" event when cancel event is emitted from the comment form', async () => {
      const wikiCommentForm = wrapper.findComponent(WikiCommentForm);
      wikiCommentForm.vm.$emit('cancel');

      await nextTick();
      expect(wrapper.emitted('cancel:edit')).toHaveLength(1);
    });

    it('should emit "creating-note:start" event when creating-note:start event is emitted from the comment form', async () => {
      const wikiCommentForm = wrapper.findComponent(WikiCommentForm);
      wikiCommentForm.vm.$emit('creating-note:start');
      await nextTick();
      expect(wrapper.emitted('creating-note:start')).toHaveLength(1);
    });

    it('should emit "creating-note:done" event when creating-note:done event is emitted from the comment form', async () => {
      const wikiCommentForm = wrapper.findComponent(WikiCommentForm);
      wikiCommentForm.vm.$emit('creating-note:done');
      await nextTick();
      expect(wrapper.emitted('creating-note:done')).toHaveLength(1);
    });

    it('should update note text correctly when creating-note:success event is emitted from the comment form', async () => {
      const wikiCommentForm = wrapper.findComponent(WikiCommentForm);
      wikiCommentForm.vm.$emit('creating-note:success', {
        ...note,
        body: 'updated note',
        bodyHtml: '<p data-sourcepos="1:1-1:29" dir="auto">updated note</p>',
      });

      wrapper.setProps({ isEditing: false });
      await nextTick();

      expect(await wrapper.findByTestId('wiki-note-content').text()).toBe('updated note');
    });
  });
});
