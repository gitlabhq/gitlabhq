import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import functionsComponent from '~/serverless/components/functions.vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/serverless/store';
import EmptyState from '~/serverless/components/empty_state.vue';
import EnvironmentRow from '~/serverless/components/environment_row.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { mockServerlessFunctions } from '../mock_data';

describe('functionsComponent', () => {
  const statusPath = `${TEST_HOST}/statusPath`;

  let component;
  let store;
  let localVue;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(statusPath).reply(200);

    localVue = createLocalVue();
    localVue.use(Vuex);

    store = createStore();
  });

  afterEach(() => {
    component.vm.$destroy();
    axiosMock.restore();
  });

  it('should render empty state when Knative is not installed', () => {
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: false,
        clustersPath: '',
        helpPath: '',
        statusPath: '',
      },
      sync: false,
    });

    expect(component.find(EmptyState).exists()).toBe(true);
  });

  it('should render a loading component', () => {
    store.dispatch('requestFunctionsLoading');
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: true,
        clustersPath: '',
        helpPath: '',
        statusPath: '',
      },
      sync: false,
    });

    expect(component.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('should render empty state when there is no function data', () => {
    store.dispatch('receiveFunctionsNoDataSuccess');
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: true,
        clustersPath: '',
        helpPath: '',
        statusPath: '',
      },
      sync: false,
    });

    expect(
      component.vm.$el
        .querySelector('.empty-state, .js-empty-state')
        .classList.contains('js-empty-state'),
    ).toBe(true);

    expect(component.vm.$el.querySelector('.state-title, .text-center').innerHTML.trim()).toEqual(
      'No functions available',
    );
  });

  it('should render the functions list', () => {
    component = shallowMount(functionsComponent, {
      localVue,
      store,
      propsData: {
        installed: true,
        clustersPath: 'clustersPath',
        helpPath: 'helpPath',
        statusPath,
      },
      sync: false,
    });

    component.vm.$store.dispatch('receiveFunctionsSuccess', mockServerlessFunctions);

    return component.vm.$nextTick().then(() => {
      expect(component.find(EnvironmentRow).exists()).toBe(true);
    });
  });
});
