/**
 * Cleans up the given element and prepares it for mounting to `@gitlab/web-ide`
 *
 * @param {Element} root The original root element
 * @returns {Element} A new element ready to be used by `@gitlab/web-ide`
 */
export const setupIdeContainer = (baseEl) => {
  const element = document.createElement('div');
  element.id = baseEl.getAttribute('id');
  element.classList.add(
    'gl-flex',
    'gl-justify-center',
    'gl-items-center',
    'gl-relative',
    'gl-h-full',
    'gl-invisible',
  );

  baseEl.insertAdjacentElement('afterend', element);

  return {
    element,
    show() {
      element.classList.remove('gl-invisible');
      baseEl.remove();
    },
  };
};
