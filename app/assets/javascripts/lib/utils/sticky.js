export const isSticky = (el, stickyTop) => {
  const top = el.getBoundingClientRect().top;

  if (top === stickyTop) {
    el.classList.add('is-stuck');
  } else {
    el.classList.remove('is-stuck');
  }
};

export default (el) => {
  const computedStyle = window.getComputedStyle(el);

  if (!/sticky/.test(computedStyle.position)) return;

  const stickyTop = parseInt(computedStyle.top, 10);

  document.addEventListener('scroll', () => isSticky(el, stickyTop), {
    passive: true,
  });
};
