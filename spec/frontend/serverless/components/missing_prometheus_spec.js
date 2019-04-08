import missingPrometheusComponent from '~/serverless/components/missing_prometheus.vue';
import { shallowMount } from '@vue/test-utils';

const createComponent = missingData =>
  shallowMount(missingPrometheusComponent, {
    propsData: {
      clustersPath: '/clusters',
      helpPath: '/help',
      missingData,
    },
    sync: false,
  }).vm;

describe('missingPrometheusComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('should render missing prometheus message', () => {
    vm = createComponent(false);

    expect(vm.$el.querySelector('.state-description').innerHTML.trim()).toContain(
      'Function invocation metrics require Prometheus to be installed first.',
    );

    expect(vm.$el.querySelector('glbutton-stub').getAttribute('variant')).toEqual('success');
  });

  it('should render no prometheus data message', () => {
    vm = createComponent(true);

    expect(vm.$el.querySelector('.state-description').innerHTML.trim()).toContain(
      'Invocation metrics loading or not available at this time.',
    );
  });
});
