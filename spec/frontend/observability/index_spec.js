import { createWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import renderObservability from '~/observability/index';
import ObservabilityApp from '~/observability/components/observability_app.vue';
import { SKELETON_VARIANTS_BY_ROUTE } from '~/observability/constants';

describe('renderObservability', () => {
  let element;
  let vueInstance;
  let component;

  const OBSERVABILITY_ROUTES = Object.keys(SKELETON_VARIANTS_BY_ROUTE);
  const SKELETON_VARIANTS = Object.values(SKELETON_VARIANTS_BY_ROUTE);

  beforeEach(() => {
    element = document.createElement('div');
    element.setAttribute('id', 'js-observability-app');
    element.dataset.observabilityIframeSrc = 'https://observe.gitlab.com/';
    document.body.appendChild(element);

    vueInstance = renderObservability();
    component = createWrapper(vueInstance).findComponent(ObservabilityApp);
  });

  afterEach(() => {
    element.remove();
  });

  it('should return a Vue instance', () => {
    expect(vueInstance).toEqual(expect.any(Vue));
  });

  it('should render the ObservabilityApp component', () => {
    expect(component.props('observabilityIframeSrc')).toBe('https://observe.gitlab.com/');
  });

  describe('skeleton variant', () => {
    it.each`
      pathDescription        | path                       | variant
      ${'dashboards'}        | ${OBSERVABILITY_ROUTES[0]} | ${SKELETON_VARIANTS[0]}
      ${'explore'}           | ${OBSERVABILITY_ROUTES[1]} | ${SKELETON_VARIANTS[1]}
      ${'manage dashboards'} | ${OBSERVABILITY_ROUTES[2]} | ${SKELETON_VARIANTS[2]}
      ${'any other'}         | ${'unknown/route'}         | ${SKELETON_VARIANTS[0]}
    `(
      'renders the $variant skeleton variant for $pathDescription path',
      async ({ path, variant }) => {
        component.vm.$router.push(path);
        await nextTick();

        expect(component.props('skeletonVariant')).toBe(variant);
      },
    );
  });

  it('handle route-update events', () => {
    component.vm.$router.push('/something?foo=bar');
    component.vm.$emit('route-update', { url: '/some_path' });
    expect(component.vm.$router.currentRoute.path).toBe('/something');
    expect(component.vm.$router.currentRoute.query).toEqual({
      foo: 'bar',
      observability_path: '/some_path',
    });
  });
});
