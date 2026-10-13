import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

const elsProcessingMap = new WeakMap();

function renderIframeEl(el) {
  const { src } = el;

  const provider = iframeProviderFor(src, el.dataset.iframeProviderId);
  if (!provider) {
    // This URL passed the allowlist at the time the Markdown content was
    // created/last updated, but no longer does. We must remove the node
    // entirely: if this instance uses the asset proxy, allowing it to remain in
    // the DOM would create a bypass. Re-modifying the source content will allow
    // it to show again (through the asset proxy, if enabled).
    el.remove();
    return;
  }

  const mountEl = document.createElement('div');
  el.hidden = true;
  el.closest('.media-container').replaceChildren(el, mountEl);

  initVueApp({
    el: mountEl,
    name: 'EmbeddedIframeRoot',
    component: EmbeddedIframe,
    props: {
      provider,
      src,
      canonicalSrc: el.dataset.iframeCanonicalSrc,
      width: el.getAttribute('width'),
      height: el.getAttribute('height'),
    },
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
