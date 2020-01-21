import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import missingPrometheusComponent from '~/serverless/components/missing_prometheus.vue';

const createComponent = missingData =>
  shallowMount(missingPrometheusComponent, {
    propsData: {
      clustersPath: '/clusters',
      helpPath: '/help',
      missingData,
    },
  });

describe('missingPrometheusComponent', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render missing prometheus message', () => {
    wrapper = createComponent(false);
    const { vm } = wrapper;

    expect(vm.$el.querySelector('.state-description').innerHTML.trim()).toContain(
      'Function invocation metrics require Prometheus to be installed first.',
    );

    expect(wrapper.find(GlButton).attributes('variant')).toBe('success');
  });

  it('should render no prometheus data message', () => {
    wrapper = createComponent(true);
    const { vm } = wrapper;

    expect(vm.$el.querySelector('.state-description').innerHTML.trim()).toContain(
      'Invocation metrics loading or not available at this time.',
    );
  });
});
