import Vue from 'vue';
import { createWrapper } from '@vue/test-utils';
import renderObservability from '~/behaviors/markdown/render_observability';
import { INLINE_EMBED_DIMENSIONS, SKELETON_VARIANT_EMBED } from '~/observability/constants';
import ObservabilityApp from '~/observability/components/observability_app.vue';

describe('renderObservability', () => {
  let subject;

  beforeEach(() => {
    subject = document.createElement('div');
    subject.classList.add('js-render-observability');
    subject.dataset.frameUrl = 'https://observe.gitlab.com/';
    document.body.appendChild(subject);
  });

  afterEach(() => {
    subject.remove();
  });

  it('should return an array of Vue instances', () => {
    const vueInstances = renderObservability([
      ...document.querySelectorAll('.js-render-observability'),
    ]);
    expect(vueInstances).toEqual([expect.any(Vue)]);
  });

  it('should correctly pass props to the ObservabilityApp component', () => {
    const vueInstances = renderObservability([
      ...document.querySelectorAll('.js-render-observability'),
    ]);

    const wrapper = createWrapper(vueInstances[0]);

    expect(wrapper.findComponent(ObservabilityApp).props()).toMatchObject({
      observabilityIframeSrc: 'https://observe.gitlab.com/',
      skeletonVariant: SKELETON_VARIANT_EMBED,
      inlineEmbed: true,
      height: INLINE_EMBED_DIMENSIONS.HEIGHT,
      width: INLINE_EMBED_DIMENSIONS.WIDTH,
    });
  });
});
