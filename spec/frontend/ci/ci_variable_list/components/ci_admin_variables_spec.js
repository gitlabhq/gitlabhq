import { shallowMount } from '@vue/test-utils';

import ciAdminVariables from '~/ci/ci_variable_list/components/ci_admin_variables.vue';
import ciVariableShared from '~/ci/ci_variable_list/components/ci_variable_shared.vue';

describe('Ci Project Variable wrapper', () => {
  let wrapper;

  const findCiShared = () => wrapper.findComponent(ciVariableShared);

  const createComponent = () => {
    wrapper = shallowMount(ciAdminVariables);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Passes down the correct props to ci_variable_shared', () => {
    expect(findCiShared().props()).toEqual({
      areScopedVariablesAvailable: false,
      componentName: 'InstanceVariables',
      entity: '',
      hideEnvironmentScope: true,
      mutationData: wrapper.vm.$options.mutationData,
      queryData: wrapper.vm.$options.queryData,
      refetchAfterMutation: true,
      fullPath: null,
      id: null,
    });
  });
});
