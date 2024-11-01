import { mount } from '@vue/test-utils';
import ModelVersionActionsDropdown from '~/ml/model_registry/components/model_version_actions_dropdown.vue';
import DeleteModelVersionDisclosureDropdownItem from '~/ml/model_registry/components/delete_model_version_disclosure_dropdown_item.vue';

describe('ml/model_registry/components/model_version_actions_dropdown', () => {
  let wrapper;

  const createWrapper = (options = {}) => {
    wrapper = mount(ModelVersionActionsDropdown, {
      provide: {
        canWriteModelRegistry: true,
      },
      propsData: {
        modelVersion: {
          version: '1.0.0',
          id: 1,
        },
      },
      ...options,
    });
  };

  const findDeleteModelVersionItem = () =>
    wrapper.findComponent(DeleteModelVersionDisclosureDropdownItem);

  it('renders delete model version item when canWriteModelRegistry is true', () => {
    createWrapper();

    expect(findDeleteModelVersionItem().exists()).toBe(true);
  });

  it('does not render delete model version item when canWriteModelRegistry is false', () => {
    createWrapper({
      provide: {
        canWriteModelRegistry: false,
      },
    });

    expect(findDeleteModelVersionItem().exists()).toBe(false);
  });

  it('emits delete-model-version event when delete button is clicked', () => {
    createWrapper();

    findDeleteModelVersionItem().vm.$emit('delete-model-version');

    expect(wrapper.emitted('delete-model-version')).toHaveLength(1);
  });
});
