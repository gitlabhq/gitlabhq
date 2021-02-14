import { GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import EmptyState from '~/serverless/components/empty_state.vue';
import EnvironmentRow from '~/serverless/components/environment_row.vue';
import functionsComponent from '~/serverless/components/functions.vue';
import { createStore } from '~/serverless/store';
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

    store = createStore({});
  });

  afterEach(() => {
    component.destroy();
    axiosMock.restore();
  });

  it('should render empty state when Knative is not installed', () => {
    store.dispatch('receiveFunctionsSuccess', { knative_installed: false });
    component = shallowMount(functionsComponent, { localVue, store });

    expect(component.find(EmptyState).exists()).toBe(true);
  });

  it('should render a loading component', () => {
    store.dispatch('requestFunctionsLoading');
    component = shallowMount(functionsComponent, { localVue, store });

    expect(component.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('should render empty state when there is no function data', () => {
    store.dispatch('receiveFunctionsNoDataSuccess', { knative_installed: true });
    component = shallowMount(functionsComponent, { localVue, store });

    expect(
      component.vm.$el
        .querySelector('.empty-state, .js-empty-state')
        .classList.contains('js-empty-state'),
    ).toBe(true);

    expect(component.vm.$el.querySelector('.state-title, .text-center').innerHTML.trim()).toEqual(
      'No functions available',
    );
  });

  it('should render functions and a loader when functions are partially fetched', () => {
    store.dispatch('receiveFunctionsPartial', {
      ...mockServerlessFunctions,
      knative_installed: 'checking',
    });

    component = shallowMount(functionsComponent, { localVue, store });

    expect(component.find('.js-functions-wrapper').exists()).toBe(true);
    expect(component.find('.js-functions-loader').exists()).toBe(true);
  });

  it('should render the functions list', () => {
    store = createStore({ clustersPath: 'clustersPath', helpPath: 'helpPath', statusPath });

    component = shallowMount(functionsComponent, { localVue, store });

    component.vm.$store.dispatch('receiveFunctionsSuccess', mockServerlessFunctions);

    return component.vm.$nextTick().then(() => {
      expect(component.find(EnvironmentRow).exists()).toBe(true);
    });
  });
});
