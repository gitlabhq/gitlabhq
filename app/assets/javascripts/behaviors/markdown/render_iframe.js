import { setAttributes } from '~/lib/utils/dom_utils';

// https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe#sandbox
const IFRAME_SANDBOX_RESTRICTIONS = 'allow-scripts allow-popups allow-same-origin';

const elsProcessingMap = new WeakMap();

function renderIframeEl(el) {
  // Obtain src from data-src first, in case image lazy loading hasn't
  // resolved this yet.  See Banzai::Filter::ImageLazyLoadFilter.
  const src = el.dataset.src || el.src;
  if (!src) return;

  const srcUrl = new URL(src);

  const allowlist = window.gon?.iframe_rendering_allowlist ?? [];
  const allowlistUrls = allowlist.map((domain) => new URL(`https://${domain}`));
  const allowed = allowlistUrls.some((allowlistUrl) => allowlistUrl.origin === srcUrl.origin);
  if (!allowed) return;

  const iframeEl = document.createElement('iframe');
  setAttributes(iframeEl, {
    src,
    sandbox: IFRAME_SANDBOX_RESTRICTIONS,
    frameBorder: 0,
    class: 'gl-inset-0 gl-h-full gl-w-full',
    allowfullscreen: 'true',
    referrerpolicy: 'strict-origin-when-cross-origin',
  });

  // We propagate these attributes, but currently the gl-h-full/gl-w-full above override them,
  // as they can easily overrun the container and break the layout.
  // For potential later use with some frontend design help.
  if (el.getAttribute('width')) {
    iframeEl.setAttribute('width', el.getAttribute('width'));
  }
  if (el.getAttribute('height')) {
    iframeEl.setAttribute('height', el.getAttribute('height'));
  }

  const wrapper = document.createElement('div');
  wrapper.appendChild(iframeEl);

  const container = el.closest('.media-container');
  container.replaceChildren(wrapper);
}

export default function renderIframes(els) {
  if (!window.gon?.iframe_rendering_enabled) return;
  if (!window.gon?.features.allowIframesInMarkdown) return;

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
