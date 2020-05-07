import { mount } from '@vue/test-utils';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';

describe('Design reply form component', () => {
  let wrapper;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.find({ ref: 'submitButton' });
  const findCancelButton = () => wrapper.find({ ref: 'cancelButton' });
  const findModal = () => wrapper.find({ ref: 'cancelCommentModal' });

  function createComponent(props = {}) {
    wrapper = mount(DesignReplyForm, {
      propsData: {
        value: '',
        isSaving: false,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('textarea has focus after component mount', () => {
    createComponent();

    expect(findTextarea().element).toEqual(document.activeElement);
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

    it('does not emit submitForm event on textarea ctrl+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('submitForm')).toBeFalsy();
      });
    });

    it('does not emit submitForm event on textarea meta+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('submitForm')).toBeFalsy();
      });
    });

    it('emits cancelForm event on pressing escape button on textarea', () => {
      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancelForm')).toBeTruthy();
    });

    it('emits cancelForm event on clicking Cancel button', () => {
      findCancelButton().vm.$emit('click');

      expect(wrapper.emitted('cancelForm')).toHaveLength(1);
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

    it('emits submitForm event on Comment button click', () => {
      findSubmitButton().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('submitForm')).toBeTruthy();
      });
    });

    it('emits submitForm event on textarea ctrl+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('submitForm')).toBeTruthy();
      });
    });

    it('emits submitForm event on textarea meta+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('submitForm')).toBeTruthy();
      });
    });

    it('emits input event on changing textarea content', () => {
      findTextarea().setValue('test2');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('input')).toBeTruthy();
      });
    });

    it('opens confirmation modal on pressing Escape button', () => {
      findTextarea().trigger('keyup.esc');

      expect(findModal().exists()).toBe(true);
    });

    it('opens confirmation modal on Cancel button click', () => {
      findCancelButton().vm.$emit('click');

      expect(findModal().exists()).toBe(true);
    });

    it('emits cancelForm event on modal Ok button click', () => {
      findTextarea().trigger('keyup.esc');
      findModal().vm.$emit('ok');

      expect(wrapper.emitted('cancelForm')).toBeTruthy();
    });
  });
});
