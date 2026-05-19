import { setAttributes } from '~/lib/utils/dom_utils';

// https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe#sandbox
export const IFRAME_SANDBOX_RESTRICTIONS = 'allow-scripts allow-popups allow-same-origin';

const elsProcessingMap = new WeakMap();

function renderIframeEl(el) {
  const { src } = el;
  if (!src) return;

  const srcUrl = new URL(src);

  const allowlist = window.gon?.iframe_rendering_allowlist ?? [];
  const allowlistUrls = allowlist.map((domain) => new URL(`https://${domain}`));
  const allowed = allowlistUrls.some((allowlistUrl) => allowlistUrl.origin === srcUrl.origin);
  if (!allowed) {
    // This URL passed the allowlist at the time the Markdown content was
    // created/last updated, but no longer does. We must remove the node
    // entirely: if this instance uses the asset proxy, allowing it to remain in
    // the DOM would create a bypass. Re-modifying the source content will allow
    // it to show again (through the asset proxy, if enabled).
    el.remove();
    return;
  }

  const width = el.getAttribute('width');
  const height = el.getAttribute('height');
  const hasExplicitDimensions = width || height;

  const iframeEl = document.createElement('iframe');
  setAttributes(iframeEl, {
    src,
    class: 'gl-border-none',
    sandbox: IFRAME_SANDBOX_RESTRICTIONS,
    allowfullscreen: 'true',
    referrerpolicy: 'strict-origin-when-cross-origin',
  });

  if (hasExplicitDimensions) {
    if (width) iframeEl.setAttribute('width', width);
    if (height) iframeEl.setAttribute('height', height);
    iframeEl.style.maxWidth = '100%';
    if (width && height) {
      iframeEl.style.aspectRatio = `${width} / ${height}`;
      iframeEl.style.height = 'auto';
    }
  } else {
    iframeEl.classList.add('gl-inset-0', 'gl-h-full', 'gl-w-full');
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
