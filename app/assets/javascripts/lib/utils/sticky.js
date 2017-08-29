export const isSticky = (el, scrollY, stickyTop) => {
  const top = Math.floor(el.offsetTop - scrollY);

  if (top <= stickyTop) {
    el.classList.add('is-stuck');
  } else {
    el.classList.remove('is-stuck');
  }
};

export default (el) => {
  if (!el) return;

  const computedStyle = window.getComputedStyle(el);

  if (!/sticky/.test(computedStyle.position)) return;

  const stickyTop = parseInt(computedStyle.top, 10);

  document.addEventListener('scroll', () => isSticky(el, window.scrollY, stickyTop), {
    passive: true,
  });
};
