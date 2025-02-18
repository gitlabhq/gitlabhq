import { GlToggle, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import IntegrationForm from '~/clusters/forms/components/integration_form.vue';
import { createStore } from '~/clusters/forms/stores/index';

Vue.use(Vuex);

describe('ClusterIntegrationForm', () => {
  let wrapper;

  const defaultStoreValues = {
    enabled: true,
    editable: true,
    environmentScope: '*',
    baseDomain: 'testDomain',
  };

  const createWrapper = (storeValues = defaultStoreValues) => {
    wrapper = shallowMount(IntegrationForm, {
      store: createStore(storeValues),
      provide: {
        autoDevopsHelpPath: 'topics/autodevops/_index',
        externalEndpointHelpPath: 'user/project/clusters/_index.md#base-domain',
      },
    });
  };

  const findSubmitButton = () => wrapper.findComponent(GlButton);
  const findGlToggle = () => wrapper.findComponent(GlToggle);
  const findClusterEnvironmentScopeInput = () => wrapper.find('[id="cluster_environment_scope"]');

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('enables toggle if editable is true', () => {
      expect(findGlToggle().props()).toMatchObject({
        disabled: false,
        label: IntegrationForm.i18n.toggleLabel,
      });
    });

    it('sets the envScope to default', () => {
      expect(findClusterEnvironmentScopeInput().attributes('value')).toBe(
        defaultStoreValues.environmentScope,
      );
    });

    it('sets the baseDomain to default', () => {
      expect(wrapper.find('[id="cluster_base_domain"]').attributes('value')).toBe('testDomain');
    });

    describe('when editable is false', () => {
      beforeEach(() => {
        createWrapper({ ...defaultStoreValues, editable: false });
      });

      it('disables toggle if editable is false', () => {
        expect(findGlToggle().props('disabled')).toBe(true);
      });

      it('does not render the save button', () => {
        expect(findSubmitButton().exists()).toBe(false);
      });
    });
  });

  describe('reactivity', () => {
    beforeEach(() => createWrapper());

    it('enables the submit button on changing toggle to different value', async () => {
      await findGlToggle().vm.$emit('change', false);
      expect(findSubmitButton().props('disabled')).toBe(false);
    });

    it('enables the submit button on changing input values', async () => {
      await findClusterEnvironmentScopeInput().vm.$emit(
        'input',
        `${defaultStoreValues.environmentScope}1`,
      );
      expect(findSubmitButton().props('disabled')).toBe(false);
    });
  });
});
