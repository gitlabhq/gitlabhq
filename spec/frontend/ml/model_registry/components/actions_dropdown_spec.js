import { mount } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';
import MlflowUsageModal from '~/ml/model_registry/components/mlflow_usage_modal.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/model_registry/constants';

describe('ml/model_registry/components/actions_dropdown', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mount(ActionsDropdown, {
      provide: {
        mlflowTrackingUrl: 'path/to/mlflow',
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      slots: {
        default: 'Slot content',
      },
    });
  };

  const findUsageModalDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findModal = () => wrapper.findComponent(MlflowUsageModal);

  beforeEach(() => {
    createWrapper();
  });

  it('renders open mlflow usage item', () => {
    expect(findUsageModalDropdownItem().text()).toBe('Using the MLflow client');
    expect(getBinding(findUsageModalDropdownItem().element, 'gl-modal').value).toBe(
      MLFLOW_USAGE_MODAL_ID,
    );
  });

  it('renders modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('renders slots', () => {
    expect(wrapper.html()).toContain('Slot content');
  });
});
