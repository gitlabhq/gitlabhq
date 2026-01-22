import { mountWikiSidebar } from './mount_sidebar';
import { mountWikiApp, mountSidebarResizer } from './mount_content';

export const mountApplications = () => {
  mountWikiApp();
  mountSidebarResizer();
  mountWikiSidebar();
};
