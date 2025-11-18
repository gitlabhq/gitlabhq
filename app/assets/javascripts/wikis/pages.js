import Wikis from './wikis';
import { mountWikiSidebarEntries } from './show';

export const mountApplications = () => {
  mountWikiSidebarEntries();

  new Wikis(); // eslint-disable-line no-new
};
