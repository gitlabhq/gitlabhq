import { GlToggle, GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import IntegrationForm from '~/clusters/forms/components/integration_form.vue';
import { createStore } from '~/clusters/forms/stores/index';

const localVue = createLocalVue();
localVue.use(Vuex);

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
      localVue,
      store: createStore(storeValues),
      provide: {
        autoDevopsHelpPath: 'topics/autodevops/index',
        externalEndpointHelpPath: 'user/clusters/applications.md',
      },
    });
  };

  const destroyWrapper = () => {
    wrapper.destroy();
    wrapper = null;
  };

  const findSubmitButton = () => wrapper.find(GlButton);
  const findGlToggle = () => wrapper.find(GlToggle);

  afterEach(() => {
    destroyWrapper();
  });

  describe('rendering', () => {
    beforeEach(() => createWrapper());

    it('enables toggle if editable is true', () => {
      expect(findGlToggle().props()).toMatchObject({
        disabled: false,
        label: IntegrationForm.i18n.toggleLabel,
      });
    });

    it('sets the envScope to default', () => {
      expect(wrapper.find('[id="cluster_environment_scope"]').attributes('value')).toBe('*');
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

    it('enables the submit button on changing toggle to different value', () => {
      return wrapper.vm
        .$nextTick()
        .then(() => {
          // setData is a bad approach because it changes the internal implementation which we should not touch
          // but our GlFormInput lacks the ability to set a new value.
          wrapper.setData({ toggleEnabled: !defaultStoreValues.enabled });
        })
        .then(() => {
          expect(findSubmitButton().props('disabled')).toBe(false);
        });
    });

    it('enables the submit button on changing input values', () => {
      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.setData({ envScope: `${defaultStoreValues.environmentScope}1` });
        })
        .then(() => {
          expect(findSubmitButton().props('disabled')).toBe(false);
        });
    });
  });
});
