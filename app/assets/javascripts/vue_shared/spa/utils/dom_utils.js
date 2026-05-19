export const updateActiveNavigation = (href) => {
  if (!href) {
    return;
  }

  const navSidebar = '#super-sidebar';
  const navSections = ':is(#super-sidebar-pinned-section, #super-sidebar-non-static-section)';
  const el = document.querySelector(navSidebar);

  if (!el) {
    return;
  }

  const activeClass = 'super-sidebar-nav-item-current';
  // Strip leading/trailing slashes so callers passing '/flows' don't produce '//flows'
  const normalizedHref = href.replace(/^\/+|\/+$/g, '');
  const escapedHref = CSS.escape(`/${normalizedHref}`);

  const currentActiveNavItems = el.querySelectorAll(`${navSections} .${activeClass}`);
  if (currentActiveNavItems.length) {
    currentActiveNavItems.forEach((foundEl) => foundEl.classList.remove(activeClass));
  }

  const newActiveNavItems = el.querySelectorAll(`${navSections} [href$="${escapedHref}"]`);

  if (newActiveNavItems) {
    newActiveNavItems.forEach((foundEl) => {
      foundEl.classList.add(activeClass);
    });
  }
};
