export const createPlaceholder = () => {
  const placeholder = document.createElement('div');
  placeholder.classList.add('sticky-placeholder');

  return placeholder;
};

export const isSticky = (el, scrollY, stickyTop, insertPlaceholder) => {
  const top = Math.floor(el.offsetTop - scrollY);

  if (top <= stickyTop && !el.classList.contains('is-stuck')) {
    const placeholder = insertPlaceholder ? createPlaceholder() : null;
    const heightBefore = el.offsetHeight;

    el.classList.add('is-stuck');

    if (insertPlaceholder) {
      el.parentNode.insertBefore(placeholder, el.nextElementSibling);

      placeholder.style.height = `${heightBefore - el.offsetHeight}px`;
    }
  } else if (top > stickyTop && el.classList.contains('is-stuck')) {
    el.classList.remove('is-stuck');

    if (
      insertPlaceholder &&
      el.nextElementSibling &&
      el.nextElementSibling.classList.contains('sticky-placeholder')
    ) {
      el.nextElementSibling.remove();
    }
  }
};

/**
 * Create a listener that will toggle a 'is-stuck' class, based on the current scroll position.
 *
 * - If the current environment does not support `position: sticky`, do nothing.
 *
 * @param {HTMLElement} el The `position: sticky` element.
 * @param {Number} stickyTop Used to determine when an element is stuck.
 * @param {Boolean} insertPlaceholder Should a placeholder element be created when element is stuck?
 */
export const stickyMonitor = (el, stickyTop, insertPlaceholder = true) => {
  if (!el) return;

  if (
    typeof CSS === 'undefined' ||
    !CSS.supports('(position: -webkit-sticky) or (position: sticky)')
  )
    return;

  document.addEventListener(
    'scroll',
    () => isSticky(el, window.scrollY, stickyTop, insertPlaceholder),
    {
      passive: true,
    },
  );
};
