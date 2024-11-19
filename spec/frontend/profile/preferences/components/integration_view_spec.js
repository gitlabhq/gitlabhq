import { nextTick } from 'vue';
import { GlFormGroup } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import IntegrationView from '~/profile/preferences/components/integration_view.vue';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';
import { integrationViews } from '../mock_data';

const viewProps = convertObjectPropsToCamelCase(integrationViews[0]);

describe('IntegrationView component', () => {
  let wrapper;
  const defaultProps = {
    config: {
      title: 'Foo',
      label: 'Enable foo',
      formName: 'foo_enabled',
    },
    value: true,
    ...viewProps,
  };

  function createComponent(props = {}) {
    return mountExtended(IntegrationView, {
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

  it('allows title to be specified via props', () => {
    wrapper = createComponent({ title: 'Custom title' });

    expect(wrapper.findByText('Custom title').exists()).toBe(true);
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
    wrapper = createComponent({ value: false });

    expect(findCheckbox().element.checked).toBe(false);
  });

  it('should render the help text', () => {
    wrapper = createComponent();

    expect(wrapper.findComponent(IntegrationHelpText).exists()).toBe(true);
  });

  describe('when prop value changes', () => {
    beforeEach(async () => {
      wrapper = createComponent();

      wrapper.setProps({ value: false });
      await nextTick();
    });

    it('should update the checkbox value', () => {
      expect(findCheckbox().element.checked).toBe(false);
    });
  });

  it('when checkbox clicked, should update the checkbox value', async () => {
    wrapper = createComponent({ value: false });

    expect(wrapper.emitted('input')).toBe(undefined);

    findCheckbox().setChecked(true);
    await nextTick();

    expect(wrapper.emitted('input')).toEqual([[true]]);
  });
});
