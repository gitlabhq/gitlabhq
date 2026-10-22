import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pageSingleton } from '~/lib/utils/page_singleton';
import EmbeddedIframe from '../components/embedded_iframe.vue';

export const iframeRenderingEnabled = () =>
  Boolean(window.gon?.iframe_rendering_providers && window.gon?.features?.allowIframesInMarkdown);

const originOf = (src) => {
  try {
    return new URL(src, window.location.origin).origin;
  } catch {
    return null;
  }
};

export const iframeProviderFor = (src, providerId) => {
  if (!iframeRenderingEnabled()) return null;

  const providers = window.gon.iframe_rendering_providers;
  if (!Object.prototype.hasOwnProperty.call(providers, providerId)) return null;

  const provider = providers[providerId];

  return provider.src_origin === originOf(src) ? provider : null;
};

export const isIframeSrcAllowed = (src, providerId) => Boolean(iframeProviderFor(src, providerId));

const elsProcessingMap = pageSingleton('render_iframe_els', () => new WeakMap());

function renderIframeEl(el) {
  const {
    iframeSrc: src,
    iframeCanonicalSrc: canonicalSrc,
    iframeProviderId,
    width,
    height,
  } = el.dataset;

  const provider = iframeProviderFor(src, iframeProviderId);
  if (!provider) return;

  const mountEl = document.createElement('div');
  el.replaceChildren(mountEl);

  initVueApp({
    el: mountEl,
    name: 'EmbeddedIframeRoot',
    component: EmbeddedIframe,
    props: { provider, src, canonicalSrc, width, height },
  });
}

export default function renderIframes(els) {
  if (!iframeRenderingEnabled()) return;

  if (!els.length) return;

  els.forEach((el) => {
    if (elsProcessingMap.has(el)) {
      return;
    }

    const requestId = window.requestIdleCallback(() => {
      renderIframeEl(el);
    });

    elsProcessingMap.set(el, requestId);
  });
}
