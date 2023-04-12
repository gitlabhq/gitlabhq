import { GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlobEditHeader from '~/blob/components/blob_edit_header.vue';

describe('Blob Header Editing', () => {
  let wrapper;
  const value = 'foo.md';

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BlobEditHeader, {
      propsData: {
        value,
        ...props,
      },
    });
  };

  const findDeleteButton = () =>
    wrapper.findAllComponents(GlButton).wrappers.find((x) => x.text() === 'Delete file');
  const findFormInput = () => wrapper.findComponent(GlFormInput);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('contains a form input field', () => {
      expect(findFormInput().exists()).toBe(true);
    });

    it('does not show delete button', () => {
      expect(findDeleteButton()).toBeUndefined();
    });
  });

  describe('functionality', () => {
    it('emits input event when the blob name is changed', () => {
      const inputComponent = findFormInput();
      const newValue = 'bar.txt';

      // update `name` with `newValue`
      inputComponent.vm.$emit('input', newValue);
      // trigger change event which emits input event on wrapper
      inputComponent.vm.$emit('change');

      expect(wrapper.emitted().input).toEqual([[newValue]]);
    });
  });

  describe.each`
    props                                     | expectedDisabled
    ${{ showDelete: true }}                   | ${false}
    ${{ showDelete: true, canDelete: false }} | ${true}
  `('with $props', ({ props, expectedDisabled }) => {
    beforeEach(() => {
      createComponent(props);
    });

    it(`shows delete button (disabled=${expectedDisabled})`, () => {
      const deleteButton = findDeleteButton();

      expect(deleteButton.exists()).toBe(true);
      expect(deleteButton.props('disabled')).toBe(expectedDisabled);
    });
  });

  describe('with delete button', () => {
    beforeEach(() => {
      createComponent({ showDelete: true, canDelete: true });
    });

    it('emits delete when clicked', () => {
      expect(wrapper.emitted().delete).toBeUndefined();

      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted().delete).toEqual([[]]);
    });
  });
});
