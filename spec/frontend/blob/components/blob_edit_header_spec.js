import { GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
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

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('contains a form input field', () => {
      expect(wrapper.findComponent(GlFormInput).exists()).toBe(true);
    });

    it('does not show delete button', () => {
      expect(findDeleteButton()).toBeUndefined();
    });
  });

  describe('functionality', () => {
    it('emits input event when the blob name is changed', async () => {
      const inputComponent = wrapper.findComponent(GlFormInput);
      const newValue = 'bar.txt';

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        name: newValue,
      });
      inputComponent.vm.$emit('change');

      await nextTick();
      expect(wrapper.emitted().input[0]).toEqual([newValue]);
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
