import Vue from 'vue';
import ObservabilityApp from '~/observability/components/observability_app.vue';
import { SKELETON_VARIANT_EMBED, INLINE_EMBED_DIMENSIONS } from '~/observability/constants';

const mountVueComponent = (element) => {
  const url = element.dataset.frameUrl;
  return new Vue({
    el: element,
    render(h) {
      return h(ObservabilityApp, {
        props: {
          observabilityIframeSrc: url,
          inlineEmbed: true,
          skeletonVariant: SKELETON_VARIANT_EMBED,
          height: INLINE_EMBED_DIMENSIONS.HEIGHT,
          width: INLINE_EMBED_DIMENSIONS.WIDTH,
        },
      });
    },
  });
};

export default function renderObservability(elements) {
  return elements.map(mountVueComponent);
}
