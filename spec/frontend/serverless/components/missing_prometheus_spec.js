import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import missingPrometheusComponent from '~/serverless/components/missing_prometheus.vue';
import { createStore } from '~/serverless/store';

describe('missingPrometheusComponent', () => {
  let wrapper;

  const createComponent = (missingData) => {
    const store = createStore({ clustersPath: '/clusters', helpPath: '/help' });

    wrapper = shallowMount(missingPrometheusComponent, { store, propsData: { missingData } });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render missing prometheus message', () => {
    createComponent(false);
    const { vm } = wrapper;

    expect(vm.$el.querySelector('.state-description').innerHTML.trim()).toContain(
      'Function invocation metrics require the Prometheus cluster integration.',
    );

    expect(wrapper.find(GlButton).attributes('variant')).toBe('success');
  });

  it('should render no prometheus data message', () => {
    createComponent(true);
    const { vm } = wrapper;

    expect(vm.$el.querySelector('.state-description').innerHTML.trim()).toContain(
      'Invocation metrics loading or not available at this time.',
    );
  });
});
