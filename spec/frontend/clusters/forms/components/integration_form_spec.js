import IntegrationForm from '~/clusters/forms/components/integration_form.vue';
import { createStore } from '~/clusters/forms/stores/index';
import { mount } from '@vue/test-utils';
import { GlToggle } from '@gitlab/ui';

describe('ClusterIntegrationForm', () => {
  let wrapper;
  let store;

  const glToggle = () => wrapper.find(GlToggle);
  const toggleButton = () => glToggle().find('button');
  const toggleInput = () => wrapper.find('input');

  const createWrapper = () => {
    store = createStore({
      enabled: 'true',
      editable: 'true',
    });
    wrapper = mount(IntegrationForm, { store });
    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    return createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('creates the toggle and label', () => {
    expect(wrapper.text()).toContain('GitLab Integration');
    expect(wrapper.contains(GlToggle)).toBe(true);
  });

  it('initializes toggle with store value', () => {
    expect(toggleButton().classes()).toContain('is-checked');
    expect(toggleInput().attributes('value')).toBe('true');
  });

  it('switches the toggle value on click', () => {
    toggleButton().trigger('click');
    wrapper.vm.$nextTick(() => {
      expect(toggleButton().classes()).not.toContain('is-checked');
      expect(toggleInput().attributes('value')).toBe('false');
    });
  });
});
