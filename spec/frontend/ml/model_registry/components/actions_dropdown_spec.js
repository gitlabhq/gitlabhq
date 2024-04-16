import { mount } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';

describe('ml/model_registry/components/actions_dropdown', () => {
  let wrapper;

  const showToast = jest.fn();

  const createWrapper = () => {
    wrapper = mount(ActionsDropdown, {
      mocks: {
        $toast: {
          show: showToast,
        },
      },
      provide: {
        mlflowTrackingUrl: 'path/to/mlflow',
      },
      slots: {
        default: 'Slot content',
      },
    });
  };

  const findCopyLinkDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  it('has data-clipboard-text set to the correct url', () => {
    createWrapper();

    expect(findCopyLinkDropdownItem().text()).toBe('Copy MLflow tracking URL');
    expect(findCopyLinkDropdownItem().attributes()['data-clipboard-text']).toBe('path/to/mlflow');
  });

  it('shows a success toast after copying the url to the clipboard', () => {
    createWrapper();

    findCopyLinkDropdownItem().find('button').trigger('click');

    expect(showToast).toHaveBeenCalledWith('Copied MLflow tracking URL to clipboard');
  });

  it('renders slots', () => {
    createWrapper();

    expect(wrapper.html()).toContain('Slot content');
  });
});
