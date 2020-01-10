import Vuex from 'vuex';

import { createLocalVue, shallowMount } from '@vue/test-utils';
import functionDetailsComponent from '~/serverless/components/function_details.vue';
import { createStore } from '~/serverless/store';

describe('functionDetailsComponent', () => {
  let localVue;
  let component;
  let store;

  beforeEach(() => {
    localVue = createLocalVue();
    localVue.use(Vuex);

    store = createStore();
  });

  afterEach(() => {
    component.vm.$destroy();
  });

  describe('Verify base functionality', () => {
    const serviceStub = {
      name: 'test',
      description: 'a description',
      environment: '*',
      url: 'http://service.com/test',
      namespace: 'test-ns',
      podcount: 0,
      metricsUrl: '/metrics',
    };

    it('has a name, description, URL, and no pods loaded', () => {
      component = shallowMount(functionDetailsComponent, {
        localVue,
        store,
        propsData: {
          func: serviceStub,
          hasPrometheus: false,
          clustersPath: '/clusters',
          helpPath: '/help',
        },
      });

      expect(
        component.vm.$el.querySelector('.serverless-function-name').innerHTML.trim(),
      ).toContain('test');

      expect(
        component.vm.$el.querySelector('.serverless-function-description').innerHTML.trim(),
      ).toContain('a description');

      expect(component.vm.$el.querySelector('p').innerHTML.trim()).toContain(
        'No pods loaded at this time.',
      );
    });

    it('has a pods loaded', () => {
      serviceStub.podcount = 1;

      component = shallowMount(functionDetailsComponent, {
        localVue,
        store,
        propsData: {
          func: serviceStub,
          hasPrometheus: false,
          clustersPath: '/clusters',
          helpPath: '/help',
        },
      });

      expect(component.vm.$el.querySelector('p').innerHTML.trim()).toContain('1 pod in use');
    });

    it('has multiple pods loaded', () => {
      serviceStub.podcount = 3;

      component = shallowMount(functionDetailsComponent, {
        localVue,
        store,
        propsData: {
          func: serviceStub,
          hasPrometheus: false,
          clustersPath: '/clusters',
          helpPath: '/help',
        },
      });

      expect(component.vm.$el.querySelector('p').innerHTML.trim()).toContain('3 pods in use');
    });

    it('can support a missing description', () => {
      serviceStub.description = null;

      component = shallowMount(functionDetailsComponent, {
        localVue,
        store,
        propsData: {
          func: serviceStub,
          hasPrometheus: false,
          clustersPath: '/clusters',
          helpPath: '/help',
        },
      });

      expect(
        component.vm.$el.querySelector('.serverless-function-description').querySelector('div')
          .innerHTML.length,
      ).toEqual(0);
    });
  });
});
