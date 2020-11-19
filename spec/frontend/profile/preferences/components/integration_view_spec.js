import { shallowMount } from '@vue/test-utils';

import { GlFormText } from '@gitlab/ui';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
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
    return shallowMount(IntegrationView, {
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

  function findCheckbox() {
    return wrapper.find('[data-testid="profile-preferences-integration-checkbox"]');
  }
  function findFormGroup() {
    return wrapper.find('[data-testid="profile-preferences-integration-form-group"]');
  }
  function findHiddenField() {
    return wrapper.find('[data-testid="profile-preferences-integration-hidden-field"]');
  }
  function findFormGroupLabel() {
    return wrapper.find('[data-testid="profile-preferences-integration-form-group"] label');
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render the title correctly', () => {
    wrapper = createComponent();

    expect(wrapper.find('label.label-bold').text()).toBe('Foo');
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

    expect(wrapper.find(GlFormText).exists()).toBe(true);
    expect(wrapper.find(IntegrationHelpText).exists()).toBe(true);
  });

  it('should render the label correctly', () => {
    wrapper = createComponent();

    expect(findFormGroupLabel().text()).toBe('Enable foo');
  });

  it('should render IntegrationView properly', () => {
    wrapper = createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
