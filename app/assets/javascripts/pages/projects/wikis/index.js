import Wikis from '~/pages/shared/wikis/wikis';
import { mountApplications } from '~/pages/shared/wikis/edit';
import { mountMoreActions } from '~/pages/shared/wikis/more_actions';
import { mountWikiSidebarEntries } from '~/pages/shared/wikis/show';

mountWikiSidebarEntries();
mountApplications();
mountMoreActions();

export default new Wikis();
