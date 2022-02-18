import { GlSprintf, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ManualVariablesForm from '~/jobs/components/manual_variables_form.vue';

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

  const createComponent = (props = {}) => {
    store = new Vuex.Store({
      actions: {
        triggerManualJob: jest.fn(),
      },
    });

    wrapper = extendedWrapper(
      mount(ManualVariablesForm, {
        propsData: { ...requiredProps, ...props },
        store,
        stubs: {
          GlSprintf,
        },
      }),
    );
  };

  const findHelpText = () => wrapper.findComponent(GlSprintf);
  const findHelpLink = () => wrapper.findComponent(GlLink);

  const findTriggerBtn = () => wrapper.findByTestId('trigger-manual-job-btn');
  const findDeleteVarBtn = () => wrapper.findByTestId('delete-variable-btn');
  const findAllDeleteVarBtns = () => wrapper.findAllByTestId('delete-variable-btn');
  const findDeleteVarBtnPlaceholder = () => wrapper.findByTestId('delete-variable-btn-placeholder');
  const findCiVariableKey = () => wrapper.findByTestId('ci-variable-key');
  const findAllCiVariableKeys = () => wrapper.findAllByTestId('ci-variable-key');
  const findCiVariableValue = () => wrapper.findByTestId('ci-variable-value');
  const findAllVariables = () => wrapper.findAllByTestId('ci-variable-row');

  const setCiVariableKey = () => {
    findCiVariableKey().setValue('new key');
    findCiVariableKey().vm.$emit('change');
    nextTick();
  };

  const setCiVariableKeyByPosition = (position, value) => {
    findAllCiVariableKeys().at(position).setValue(value);
    findAllCiVariableKeys().at(position).vm.$emit('change');
    nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('creates a new variable when user enters a new key value', async () => {
    expect(findAllVariables()).toHaveLength(1);

    await setCiVariableKey();

    expect(findAllVariables()).toHaveLength(2);
  });

  it('does not create extra empty variables', async () => {
    expect(findAllVariables()).toHaveLength(1);

    await setCiVariableKey();

    expect(findAllVariables()).toHaveLength(2);

    await setCiVariableKey();

    expect(findAllVariables()).toHaveLength(2);
  });

  it('removes the correct variable row', async () => {
    const variableKeyNameOne = 'key-one';
    const variableKeyNameThree = 'key-three';

    await setCiVariableKeyByPosition(0, variableKeyNameOne);

    await setCiVariableKeyByPosition(1, 'key-two');

    await setCiVariableKeyByPosition(2, variableKeyNameThree);

    expect(findAllVariables()).toHaveLength(4);

    await findAllDeleteVarBtns().at(1).trigger('click');

    expect(findAllVariables()).toHaveLength(3);

    expect(findAllCiVariableKeys().at(0).element.value).toBe(variableKeyNameOne);
    expect(findAllCiVariableKeys().at(1).element.value).toBe(variableKeyNameThree);
    expect(findAllCiVariableKeys().at(2).element.value).toBe('');
  });

  it('trigger button is disabled after trigger action', async () => {
    expect(findTriggerBtn().props('disabled')).toBe(false);

    await findTriggerBtn().trigger('click');

    expect(findTriggerBtn().props('disabled')).toBe(true);
  });

  it('delete variable button should only show when there is more than one variable', async () => {
    expect(findDeleteVarBtn().exists()).toBe(false);

    await setCiVariableKey();

    expect(findDeleteVarBtn().exists()).toBe(true);
  });

  it('delete variable button placeholder should only exist when a user cannot remove', async () => {
    expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
  });

  it('renders help text with provided link', () => {
    expect(findHelpText().exists()).toBe(true);
    expect(findHelpLink().attributes('href')).toBe(
      '/help/ci/variables/index#add-a-cicd-variable-to-a-project',
    );
  });

  it('passes variables in correct format', async () => {
    jest.spyOn(store, 'dispatch');

    await setCiVariableKey();

    await findCiVariableValue().setValue('new value');

    await findTriggerBtn().trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('triggerManualJob', [
      {
        key: 'new key',
        secret_value: 'new value',
      },
    ]);
  });
});
