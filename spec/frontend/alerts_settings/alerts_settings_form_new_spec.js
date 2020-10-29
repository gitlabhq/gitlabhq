import { shallowMount } from '@vue/test-utils';
import { GlForm, GlFormSelect, GlCollapse, GlFormInput } from '@gitlab/ui';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form_new.vue';
import { defaultAlertSettingsConfig } from './util';

jest.mock('~/alerts_settings/services');

describe('AlertsSettingsFormNew', () => {
  let wrapper;

  const createComponent = ({ methods } = {}, data) => {
    wrapper = shallowMount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      provide: {
        ...defaultAlertSettingsConfig,
      },
      methods,
      stubs: { GlCollapse, GlFormInput },
    });
  };

  const findForm = () => wrapper.find(GlForm);
  const findSelect = () => wrapper.find(GlFormSelect);
  const findFormSteps = () => wrapper.find(GlCollapse);
  const findFormName = () => wrapper.find(GlFormInput);

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the initial template', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('render the initial form with only an integration type dropdown', () => {
      expect(findForm().exists()).toBe(true);
      expect(findSelect().exists()).toBe(true);
      expect(findFormSteps().attributes('visible')).toBeUndefined();
    });

    it('shows the rest of the form when the dropdown is used', async () => {
      findSelect().vm.$emit('change', 'prometheus');

      await wrapper.vm.$nextTick();

      expect(findFormName().isVisible()).toBe(true);
    });
  });
});
