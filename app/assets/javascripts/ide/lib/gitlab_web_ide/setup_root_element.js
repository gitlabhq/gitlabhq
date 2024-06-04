/**
 * Cleans up the given element and prepares it for mounting to `@gitlab/web-ide`
 *
 * @param {Element} root The original root element
 * @returns {Element} A new element ready to be used by `@gitlab/web-ide`
 */
export const setupRootElement = (el) => {
  const newEl = document.createElement(el.tagName);
  newEl.id = el.id;
  newEl.classList.add(
    'gl-flex',
    'gl-justify-center',
    'gl-items-center',
    'gl-relative',
    'gl-h-full',
  );
  el.replaceWith(newEl);

  return newEl;
};
