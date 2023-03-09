import { GlFormGroup } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';
import { integrationViews, userFields } from '../mock_data';

const viewProps = convertObjectPropsToCamelCase(integrationViews[0]);

describe('IntegrationView component', () => {
  let wrapper;
  const defaultProps = {
    config: {
      title: 'Foo',
      label: 'Enable foo',
      formName: 'foo_enabled',
    },
    ...viewProps,
  };

  function createComponent(options = {}) {
    const { props = {}, provide = {} } = options;
    return mountExtended(IntegrationView, {
      provide: {
        userFields,
        ...provide,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  const findCheckbox = () => wrapper.findByLabelText(new RegExp(defaultProps.config.label));
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findHiddenField = () =>
    wrapper.findByTestId('profile-preferences-integration-hidden-field');

  it('should render the form group legend correctly', () => {
    wrapper = createComponent();

    expect(wrapper.findByText(defaultProps.config.title).exists()).toBe(true);
  });

  it('should render the form correctly', () => {
    wrapper = createComponent();

    expect(findFormGroup().exists()).toBe(true);
    expect(findHiddenField().exists()).toBe(true);
    expect(findCheckbox().exists()).toBe(true);
    expect(findCheckbox().attributes('id')).toBe('user_foo_enabled');
    expect(findCheckbox().attributes('name')).toBe('user[foo_enabled]');
  });

  it('should have the checkbox value to be set to 1', () => {
    wrapper = createComponent();

    expect(findCheckbox().attributes('value')).toBe('1');
  });

  it('should have the hidden value to be set to 0', () => {
    wrapper = createComponent();

    expect(findHiddenField().attributes('value')).toBe('0');
  });

  it('should set the checkbox value to be true', () => {
    wrapper = createComponent();

    expect(findCheckbox().element.checked).toBe(true);
  });

  it('should set the checkbox value to be false when false is provided', () => {
    wrapper = createComponent({
      provide: {
        userFields: {
          foo_enabled: false,
        },
      },
    });

    expect(findCheckbox().element.checked).toBe(false);
  });

  it('should set the checkbox value to be false when not provided', () => {
    wrapper = createComponent({ provide: { userFields: {} } });

    expect(findCheckbox().element.checked).toBe(false);
  });

  it('should render the help text', () => {
    wrapper = createComponent();

    expect(wrapper.findComponent(IntegrationHelpText).exists()).toBe(true);
  });
});
