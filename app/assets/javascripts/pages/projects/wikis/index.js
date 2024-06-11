import Wikis from '~/pages/shared/wikis/wikis';
import { mountApplications } from '~/pages/shared/wikis/edit';
import { mountMoreActions } from '~/pages/shared/wikis/more_actions';

mountApplications();
mountMoreActions();

export default new Wikis();
