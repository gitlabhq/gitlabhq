import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';

export const mountLegacyToggleButton = () => {
  const toggleButton = document.querySelector('.js-sidebar-wiki-toggle-open');
  if (!toggleButton) return;

  toggleButton.addEventListener('click', toggleWikiSidebar);
};
