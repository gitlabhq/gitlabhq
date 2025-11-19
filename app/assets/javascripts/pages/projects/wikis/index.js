import Wikis from '~/wikis/wikis';
import { mountApplications } from '~/wikis/edit';
import { mountMoreActions } from '~/wikis/more_actions';
import { mountWikiSidebar } from '~/wikis/show';

mountWikiSidebar();
mountApplications();
mountMoreActions();

export default new Wikis();
