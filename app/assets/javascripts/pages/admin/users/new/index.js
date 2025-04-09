import {
  setupInternalUserRegexHandler,
  initAdminNewUserOrganizationField,
} from '~/admin/users/new';
import { initUserTypeSelector } from '~/admin/users/user_type_selector';

setupInternalUserRegexHandler();
initAdminNewUserOrganizationField();
initUserTypeSelector();
