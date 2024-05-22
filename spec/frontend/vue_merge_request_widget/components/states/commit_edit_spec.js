import { GlFormTextarea } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CommitEdit from '~/vue_merge_request_widget/components/states/commit_edit.vue';

const testCommitMessage = 'Test commit message';
const testLabel = 'Test label';
const testInputId = 'test-input-id';

describe('Commits edit component', () => {
  let wrapper;

  const createComponent = (slots = {}) => {
    wrapper = shallowMount(CommitEdit, {
      propsData: {
        value: testCommitMessage,
        label: testLabel,
        inputId: testInputId,
      },
      slots: {
        ...slots,
      },
      stubs: {
        GlFormTextarea,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findTextarea = () => wrapper.findComponent(GlFormTextarea);

  it('has a correct label', () => {
    const labelElement = wrapper.find('.col-form-label');

    expect(labelElement.text()).toBe(testLabel);
  });

  describe('textarea', () => {
    it('has a correct ID', () => {
      expect(findTextarea().attributes('id')).toBe(testInputId);
    });

    it('has a correct value', () => {
      expect(findTextarea().props('value')).toBe(testCommitMessage);
    });

    it('emits an input event and receives changed value', async () => {
      const changedCommitMessage = 'Changed commit message';

      wrapper.setProps({ value: changedCommitMessage });
      findTextarea().vm.$emit('input', changedCommitMessage);

      await nextTick();
      expect(wrapper.emitted('input')).toEqual([[changedCommitMessage]]);
      expect(findTextarea().props('value')).toBe(changedCommitMessage);
    });
  });

  describe('when slots are present', () => {
    beforeEach(() => {
      createComponent({
        header: `<div class="test-header">${testCommitMessage}</div>`,
      });
    });

    it('renders header slot correctly', () => {
      const headerSlotElement = wrapper.find('.test-header');

      expect(headerSlotElement.exists()).toBe(true);
      expect(headerSlotElement.text()).toBe(testCommitMessage);
    });
  });
});
