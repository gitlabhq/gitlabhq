import { shallowMount } from '@vue/test-utils';
import environmentRowComponent from '~/serverless/components/environment_row.vue';

import { mockServerlessFunctions, mockServerlessFunctionsDiffEnv } from '../mock_data';
import { translate } from '~/serverless/utils';

const createComponent = (env, envName) =>
  shallowMount(environmentRowComponent, { propsData: { env, envName }, sync: false }).vm;

describe('environment row component', () => {
  describe('default global cluster case', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent(translate(mockServerlessFunctions.functions)['*'], '*');
    });

    afterEach(() => vm.$destroy());

    it('has the correct envId', () => {
      expect(vm.envId).toEqual('env-global');
    });

    it('is open by default', () => {
      expect(vm.isOpenClass).toEqual({ 'is-open': true });
    });

    it('generates correct output', () => {
      expect(vm.$el.id).toEqual('env-global');
      expect(vm.$el.classList.contains('is-open')).toBe(true);
      expect(vm.$el.querySelector('div.title').innerHTML.trim()).toEqual('*');
    });

    it('opens and closes correctly', () => {
      expect(vm.isOpen).toBe(true);

      vm.toggleOpen();

      expect(vm.isOpen).toBe(false);
    });
  });

  describe('default named cluster case', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent(translate(mockServerlessFunctionsDiffEnv.functions).test, 'test');
    });

    afterEach(() => vm.$destroy());

    it('has the correct envId', () => {
      expect(vm.envId).toEqual('env-test');
    });

    it('is open by default', () => {
      expect(vm.isOpenClass).toEqual({ 'is-open': true });
    });

    it('generates correct output', () => {
      expect(vm.$el.id).toEqual('env-test');
      expect(vm.$el.classList.contains('is-open')).toBe(true);
      expect(vm.$el.querySelector('div.title').innerHTML.trim()).toEqual('test');
    });
  });
});
