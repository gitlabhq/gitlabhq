import Wikis from './wikis';
import { mountWikiSidebar } from './show';

export const mountApplications = () => {
  mountWikiSidebar();

  new Wikis(); // eslint-disable-line no-new
};
