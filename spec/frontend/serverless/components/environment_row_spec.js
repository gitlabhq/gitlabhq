import { createLocalVue, shallowMount } from '@vue/test-utils';
import environmentRowComponent from '~/serverless/components/environment_row.vue';

import { mockServerlessFunctions, mockServerlessFunctionsDiffEnv } from '../mock_data';
import { translate } from '~/serverless/utils';

const createComponent = (localVue, env, envName) =>
  shallowMount(environmentRowComponent, { localVue, propsData: { env, envName }, sync: false }).vm;

describe('environment row component', () => {
  describe('default global cluster case', () => {
    let localVue;
    let vm;

    beforeEach(() => {
      localVue = createLocalVue();
      vm = createComponent(localVue, translate(mockServerlessFunctions.functions)['*'], '*');
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
    let localVue;

    beforeEach(() => {
      localVue = createLocalVue();
      vm = createComponent(
        localVue,
        translate(mockServerlessFunctionsDiffEnv.functions).test,
        'test',
      );
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
