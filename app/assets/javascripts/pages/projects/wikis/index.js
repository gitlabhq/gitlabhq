import Wikis from '~/wikis/wikis';
import { mountApplications } from '~/wikis/edit';
import { mountMoreActions } from '~/wikis/more_actions';
import { mountWikiSidebarEntries } from '~/wikis/show';

mountWikiSidebarEntries();
mountApplications();
mountMoreActions();

export default new Wikis();
