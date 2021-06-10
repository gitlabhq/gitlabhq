export const hasMenuExpanded = () => {
  const header = document.querySelector('.header-content');

  return Boolean(header?.classList.contains('menu-expanded'));
};
