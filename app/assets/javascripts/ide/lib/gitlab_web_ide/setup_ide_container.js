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
    'gl-hidden',
    'gl-justify-center',
    'gl-items-center',
    'gl-relative',
    'gl-h-full',
  );

  baseEl.insertAdjacentElement('afterend', element);

  return {
    element,
    show() {
      element.classList.add('gl-flex');
      element.classList.remove('gl-hidden');
      baseEl.remove();
    },
  };
};
