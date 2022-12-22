import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Autosave from '~/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/autosave');

describe('Design reply form component', () => {
  let wrapper;
  let originalGon;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.findComponent({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.findComponent({ ref: 'cancelButton' });

  function createComponent(props = {}, mountOptions = {}) {
    wrapper = mount(DesignReplyForm, {
      propsData: {
        value: '',
        isSaving: false,
        noteableId: 'gid://gitlab/DesignManagement::Design/6',
        ...props,
      },
      ...mountOptions,
    });
  }

  beforeEach(() => {
    originalGon = window.gon;
    window.gon.current_user_id = 1;
  });

  afterEach(() => {
    wrapper.destroy();
    window.gon = originalGon;
    confirmAction.mockReset();
  });

  it('textarea has focus after component mount', () => {
    // We need to attach to document, so that `document.activeElement` is properly set in jsdom
    createComponent({}, { attachTo: document.body });

    expect(findTextarea().element).toEqual(document.activeElement);
  });

  it('renders "Attach a file or image" button in markdown toolbar', () => {
    createComponent();

    expect(wrapper.find('[data-testid="button-attach-file"]').exists()).toBe(true);
  });

  it('renders file upload progress container', () => {
    createComponent();

    expect(wrapper.find('.comment-toolbar .uploading-container').exists()).toBe(true);
  });

  it('renders button text as "Comment" when creating a comment', () => {
    createComponent();

    expect(findSubmitButton().html()).toMatchSnapshot();
  });

  it('renders button text as "Save comment" when creating a comment', () => {
    createComponent({ isNewComment: false });

    expect(findSubmitButton().html()).toMatchSnapshot();
  });

  it.each`
    discussionId                         | shortDiscussionId
    ${undefined}                         | ${'new'}
    ${'gid://gitlab/DiffDiscussion/123'} | ${123}
  `(
    'initializes autosave support on discussion with proper key',
    async ({ discussionId, shortDiscussionId }) => {
      createComponent({ discussionId });
      await nextTick();

      expect(Autosave).toHaveBeenCalledWith(expect.any(Element), [
        'Discussion',
        6,
        shortDiscussionId,
      ]);
    },
  );

  describe('when form has no text', () => {
    beforeEach(() => {
      createComponent({
        value: '',
      });
    });

    it('submit button is disabled', () => {
      expect(findSubmitButton().attributes().disabled).toBe('disabled');
    });

    it('does not emit submitForm event on textarea ctrl+enter keydown', async () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeUndefined();
    });

    it('does not emit submitForm event on textarea meta+enter keydown', async () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeUndefined();
    });

    it('emits cancelForm event on pressing escape button on textarea', () => {
      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('emits cancelForm event on clicking Cancel button', () => {
      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });
  });

  describe('when form has text', () => {
    beforeEach(() => {
      createComponent({
        value: 'test',
      });
    });

    it('submit button is enabled', () => {
      expect(findSubmitButton().attributes().disabled).toBeUndefined();
    });

    it('emits submitForm event on Comment button click', async () => {
      const autosaveResetSpy = jest.spyOn(Autosave.prototype, 'reset');

      findSubmitButton().vm.$emit('click');

      await nextTick();
      expect(wrapper.emitted('submit-form')).toHaveLength(1);
      expect(autosaveResetSpy).toHaveBeenCalled();
    });

    it('emits submitForm event on textarea ctrl+enter keydown', async () => {
      const autosaveResetSpy = jest.spyOn(Autosave.prototype, 'reset');

      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toHaveLength(1);
      expect(autosaveResetSpy).toHaveBeenCalled();
    });

    it('emits submitForm event on textarea meta+enter keydown', async () => {
      const autosaveResetSpy = jest.spyOn(Autosave.prototype, 'reset');

      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toHaveLength(1);
      expect(autosaveResetSpy).toHaveBeenCalled();
    });

    it('emits input event on changing textarea content', async () => {
      findTextarea().setValue('test2');

      await nextTick();
      expect(wrapper.emitted('input')).toEqual([['test2']]);
    });

    it('emits cancelForm event on Escape key if text was not changed', () => {
      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('opens confirmation modal on Escape key when text has changed', async () => {
      wrapper.setProps({ value: 'test2' });

      await nextTick();
      findTextarea().trigger('keyup.esc');
      expect(confirmAction).toHaveBeenCalled();
    });

    it('emits cancelForm event on Cancel button click if text was not changed', () => {
      findCancelButton().trigger('click');

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
    });

    it('opens confirmation modal on Cancel button click when text has changed', async () => {
      wrapper.setProps({ value: 'test2' });

      await nextTick();
      findCancelButton().trigger('click');
      expect(confirmAction).toHaveBeenCalled();
    });

    it('emits cancelForm event when confirmed', async () => {
      confirmAction.mockResolvedValueOnce(true);
      const autosaveResetSpy = jest.spyOn(Autosave.prototype, 'reset');

      wrapper.setProps({ value: 'test3' });
      await nextTick();

      findTextarea().trigger('keyup.esc');
      await nextTick();

      expect(confirmAction).toHaveBeenCalled();
      await nextTick();

      expect(wrapper.emitted('cancel-form')).toHaveLength(1);
      expect(autosaveResetSpy).toHaveBeenCalled();
    });

    it("doesn't emit cancelForm event when not confirmed", async () => {
      confirmAction.mockResolvedValueOnce(false);
      const autosaveResetSpy = jest.spyOn(Autosave.prototype, 'reset');

      wrapper.setProps({ value: 'test3' });
      await nextTick();

      findTextarea().trigger('keyup.esc');
      await nextTick();

      expect(confirmAction).toHaveBeenCalled();
      await nextTick();

      expect(wrapper.emitted('cancel-form')).toBeUndefined();
      expect(autosaveResetSpy).not.toHaveBeenCalled();
    });
  });
});
