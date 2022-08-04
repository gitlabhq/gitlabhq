import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';

const showModal = jest.fn();

const GlModal = {
  template: '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-ok"></slot></div>',
  methods: {
    show: showModal,
  },
};

describe('Design reply form component', () => {
  let wrapper;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.find({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.find({ ref: 'cancelButton' });
  const findModal = () => wrapper.find({ ref: 'cancelCommentModal' });

  function createComponent(props = {}, mountOptions = {}) {
    wrapper = mount(DesignReplyForm, {
      propsData: {
        value: '',
        isSaving: false,
        ...props,
      },
      stubs: { GlModal },
      ...mountOptions,
    });
  }

  afterEach(() => {
    wrapper.destroy();
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

  describe('when form has no text', () => {
    beforeEach(() => {
      createComponent({
        value: '',
      });
    });

    it('submit button is disabled', () => {
      expect(findSubmitButton().attributes().disabled).toBeTruthy();
    });

    it('does not emit submitForm event on textarea ctrl+enter keydown', async () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeFalsy();
    });

    it('does not emit submitForm event on textarea meta+enter keydown', async () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeFalsy();
    });

    it('emits cancelForm event on pressing escape button on textarea', () => {
      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancel-form')).toBeTruthy();
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
      expect(findSubmitButton().attributes().disabled).toBeFalsy();
    });

    it('emits submitForm event on Comment button click', async () => {
      findSubmitButton().vm.$emit('click');

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeTruthy();
    });

    it('emits submitForm event on textarea ctrl+enter keydown', async () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeTruthy();
    });

    it('emits submitForm event on textarea meta+enter keydown', async () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      await nextTick();
      expect(wrapper.emitted('submit-form')).toBeTruthy();
    });

    it('emits input event on changing textarea content', async () => {
      findTextarea().setValue('test2');

      await nextTick();
      expect(wrapper.emitted('input')).toBeTruthy();
    });

    it('emits cancelForm event on Escape key if text was not changed', () => {
      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancel-form')).toBeTruthy();
    });

    it('opens confirmation modal on Escape key when text has changed', async () => {
      wrapper.setProps({ value: 'test2' });

      await nextTick();
      findTextarea().trigger('keyup.esc');
      expect(showModal).toHaveBeenCalled();
    });

    it('emits cancelForm event on Cancel button click if text was not changed', () => {
      findCancelButton().trigger('click');

      expect(wrapper.emitted('cancel-form')).toBeTruthy();
    });

    it('opens confirmation modal on Cancel button click when text has changed', async () => {
      wrapper.setProps({ value: 'test2' });

      await nextTick();
      findCancelButton().trigger('click');
      expect(showModal).toHaveBeenCalled();
    });

    it('emits cancelForm event on modal Ok button click', () => {
      findTextarea().trigger('keyup.esc');
      findModal().vm.$emit('ok');

      expect(wrapper.emitted('cancel-form')).toBeTruthy();
    });
  });
});
