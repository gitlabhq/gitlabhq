export const updateActiveNavigation = (href) => {
  const navSection = '#super-sidebar';
  const el = document.querySelector(navSection);

  if (!el) {
    return;
  }

  const activeClass = 'super-sidebar-nav-item-current';

  const currentActiveNavItems = el.querySelectorAll(`.${activeClass}`);

  if (currentActiveNavItems.length) {
    currentActiveNavItems.forEach((foundEl) => foundEl.classList.remove(activeClass));
  }

  const newActiveNavItems = el.querySelectorAll(`[href*="${href}"]`);

  if (newActiveNavItems) {
    newActiveNavItems.forEach((foundEl) => {
      foundEl.classList.add(activeClass);
    });
  }
};
