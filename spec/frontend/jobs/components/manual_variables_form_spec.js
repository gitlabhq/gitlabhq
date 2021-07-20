import { GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Form from '~/jobs/components/manual_variables_form.vue';

const localVue = createLocalVue();

Vue.use(Vuex);

describe('Manual Variables Form', () => {
  let wrapper;
  let store;

  const requiredProps = {
    action: {
      path: '/play',
      method: 'post',
      button_title: 'Trigger this manual action',
    },
  };

  const createComponent = ({ props = {}, mountFn = shallowMount } = {}) => {
    store = new Vuex.Store({
      actions: {
        triggerManualJob: jest.fn(),
      },
    });

    wrapper = extendedWrapper(
      mountFn(localVue.extend(Form), {
        propsData: { ...requiredProps, ...props },
        localVue,
        store,
        stubs: {
          GlSprintf,
        },
      }),
    );
  };

  const findInputKey = () => wrapper.findComponent({ ref: 'inputKey' });
  const findInputValue = () => wrapper.findComponent({ ref: 'inputSecretValue' });
  const findHelpText = () => wrapper.findComponent(GlSprintf);
  const findHelpLink = () => wrapper.findComponent(GlLink);

  const findTriggerBtn = () => wrapper.findByTestId('trigger-manual-job-btn');
  const findDeleteVarBtn = () => wrapper.findByTestId('delete-variable-btn');
  const findCiVariableKey = () => wrapper.findByTestId('ci-variable-key');
  const findCiVariableValue = () => wrapper.findByTestId('ci-variable-value');
  const findAllVariables = () => wrapper.findAllByTestId('ci-variable-row');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('shallowMount', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty form with correct placeholders', () => {
      expect(findInputKey().attributes('placeholder')).toBe('Input variable key');
      expect(findInputValue().attributes('placeholder')).toBe('Input variable value');
    });

    it('renders help text with provided link', () => {
      expect(findHelpText().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(
        '/help/ci/variables/index#add-a-cicd-variable-to-a-project',
      );
    });

    describe('when adding a new variable', () => {
      it('creates a new variable when user types a new key and resets the form', async () => {
        await findInputKey().setValue('new key');

        expect(findAllVariables()).toHaveLength(1);
        expect(findCiVariableKey().element.value).toBe('new key');
        expect(findInputKey().attributes('value')).toBe(undefined);
      });

      it('creates a new variable when user types a new value and resets the form', async () => {
        await findInputValue().setValue('new value');

        expect(findAllVariables()).toHaveLength(1);
        expect(findCiVariableValue().element.value).toBe('new value');
        expect(findInputValue().attributes('value')).toBe(undefined);
      });
    });
  });

  describe('mount', () => {
    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    describe('when deleting a variable', () => {
      it('removes the variable row', async () => {
        await wrapper.setData({
          variables: [
            {
              key: 'new key',
              secret_value: 'value',
              id: '1',
            },
          ],
        });

        findDeleteVarBtn().trigger('click');

        await wrapper.vm.$nextTick();

        expect(findAllVariables()).toHaveLength(0);
      });
    });

    it('trigger button is disabled after trigger action', async () => {
      expect(findTriggerBtn().props('disabled')).toBe(false);

      await findTriggerBtn().trigger('click');

      expect(findTriggerBtn().props('disabled')).toBe(true);
    });
  });
});
