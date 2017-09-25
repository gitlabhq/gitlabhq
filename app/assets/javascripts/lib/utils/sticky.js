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

    if (insertPlaceholder && el.nextElementSibling.classList.contains('sticky-placeholder')) {
      el.nextElementSibling.remove();
    }
  }
};

export default (el, insertPlaceholder = true) => {
  if (!el) return;

  const computedStyle = window.getComputedStyle(el);

  if (!/sticky/.test(computedStyle.position)) return;

  const stickyTop = parseInt(computedStyle.top, 10);

  document.addEventListener('scroll', () => isSticky(el, window.scrollY, stickyTop, insertPlaceholder), {
    passive: true,
  });
};
