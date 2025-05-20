import {
  setupInternalUserRegexHandler,
  initAdminNewUserOrganizationField,
} from '~/admin/users/new';
import { initUserTypeSelector } from 'ee_else_ce/admin/users/user_type_selector';

setupInternalUserRegexHandler();
initAdminNewUserOrganizationField();
initUserTypeSelector();
