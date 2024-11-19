import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import NewUserOrganizationField from './components/new_user_organization_field.vue';

const DATA_ATTR_REGEX_PATTERN = 'data-user-internal-regex-pattern';
const DATA_ATTR_REGEX_OPTIONS = 'data-user-internal-regex-options';
export const ID_USER_EXTERNAL = 'user_external';
export const ID_WARNING = 'warning_external_automatically_set';
export const ID_USER_EMAIL = 'user_email';

const getAttributeValue = (attr) => document.querySelector(`[${attr}]`)?.getAttribute(attr);

const getRegexPattern = () => getAttributeValue(DATA_ATTR_REGEX_PATTERN);

const getRegexOptions = () => getAttributeValue(DATA_ATTR_REGEX_OPTIONS);

export const setupInternalUserRegexHandler = () => {
  const regexPattern = getRegexPattern();

  if (!regexPattern) {
    return;
  }

  const regexOptions = getRegexOptions();
  const elExternal = document.getElementById(ID_USER_EXTERNAL);
  const elWarningMessage = document.getElementById(ID_WARNING);
  const elUserEmail = document.getElementById(ID_USER_EMAIL);

  const isEmailInternal = (email) => {
    const regex = new RegExp(regexPattern, regexOptions);
    return regex.test(email);
  };

  const setExternalCheckbox = (email) => {
    const isChecked = elExternal.checked;

    if (isEmailInternal(email)) {
      if (isChecked) {
        elExternal.checked = false;
        elWarningMessage.classList.remove('hidden');
      }
    } else if (!isChecked) {
      elExternal.checked = true;
      elWarningMessage.classList.add('hidden');
    }
  };

  const setupListeners = () => {
    elUserEmail.addEventListener('input', (event) => {
      setExternalCheckbox(event.target.value);
    });

    elExternal.addEventListener('change', () => {
      elWarningMessage.classList.add('hidden');
    });
  };

  setupListeners();
};

export const initAdminNewUserOrganizationField = () => {
  Vue.use(VueApollo);

  const el = document.getElementById('js-admin-new-user-organization-field');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { hasMultipleOrganizations, initialOrganization } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
    { deep: true },
  );

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'AdminNewUserOrganizationFieldRoot',
    apolloProvider,
    render(createElement) {
      return createElement(NewUserOrganizationField, {
        props: { hasMultipleOrganizations, initialOrganization },
      });
    },
  });
};
