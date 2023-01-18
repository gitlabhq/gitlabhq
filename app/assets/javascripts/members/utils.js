import { isUndefined } from 'lodash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getParameterByName, setUrlParams } from '~/lib/utils/url_utility';
import {
  FIELDS,
  DEFAULT_SORT,
  GROUP_LINK_BASE_PROPERTY_NAME,
  GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
  I18N_USER_YOU,
  I18N_USER_BLOCKED,
  I18N_USER_BOT,
  I188N_USER_2FA,
} from './constants';

export const generateBadges = ({ member, isCurrentUser, canManageMembers }) => [
  {
    show: isCurrentUser,
    text: I18N_USER_YOU,
    variant: 'success',
  },
  {
    show: member.user?.blocked,
    text: I18N_USER_BLOCKED,
    variant: 'danger',
  },
  {
    show: member.user?.isBot,
    text: I18N_USER_BOT,
    variant: 'muted',
  },
  {
    show: member.user?.twoFactorEnabled && (canManageMembers || isCurrentUser),
    text: I188N_USER_2FA,
    variant: 'info',
  },
];

export const isGroup = (member) => {
  return Boolean(member.sharedWithGroup);
};

export const isDirectMember = (member) => {
  return member.isDirectMember;
};

export const isCurrentUser = (member, currentUserId) => {
  return member.user?.id === currentUserId;
};

export const canRemove = (member) => {
  return isDirectMember(member) && member.canRemove;
};

export const canRemoveBlockedByLastOwner = (member, canManageMembers) =>
  isDirectMember(member) && canManageMembers && member.isLastOwner;

export const canResend = (member) => {
  return Boolean(member.invite?.canResend);
};

export const canUpdate = (member, currentUserId) => {
  return !isCurrentUser(member, currentUserId) && isDirectMember(member) && member.canUpdate;
};

export const parseSortParam = (sortableFields) => {
  const sortParam = getParameterByName('sort');

  const sortedField = FIELDS.filter((field) => sortableFields.includes(field.key)).find(
    (field) => field.sort?.asc === sortParam || field.sort?.desc === sortParam,
  );

  if (!sortedField) {
    return DEFAULT_SORT;
  }

  return {
    sortByKey: sortedField.key,
    sortDesc: sortedField?.sort?.desc === sortParam,
  };
};

export const buildSortHref = ({
  sortBy,
  sortDesc,
  filteredSearchBarTokens,
  filteredSearchBarSearchParam,
}) => {
  const sortDefinition = FIELDS.find((field) => field.key === sortBy)?.sort;

  if (!sortDefinition) {
    return '';
  }

  const sortParam = sortDesc ? sortDefinition.desc : sortDefinition.asc;

  const filterParams =
    filteredSearchBarTokens?.reduce((accumulator, token) => {
      return {
        ...accumulator,
        [token]: getParameterByName(token),
      };
    }, {}) || {};

  if (filteredSearchBarSearchParam) {
    filterParams[filteredSearchBarSearchParam] = getParameterByName(filteredSearchBarSearchParam);
  }

  return setUrlParams({ ...filterParams, sort: sortParam }, window.location.href, true);
};

// Defined in `ee/app/assets/javascripts/members/utils.js`
export const canDisableTwoFactor = () => false;

// Defined in `ee/app/assets/javascripts/members/utils.js`
export const canOverride = () => false;

// Defined in `ee/app/assets/javascripts/members/utils.js`
export const canUnban = () => false;

export const parseDataAttributes = (el) => {
  const { membersData } = el.dataset;

  return convertObjectPropsToCamelCase(JSON.parse(membersData), {
    deep: true,
    ignoreKeyNames: ['params'],
  });
};

export const baseRequestFormatter = (basePropertyName, accessLevelPropertyName) => ({
  accessLevel,
  ...otherProperties
}) => {
  const accessLevelProperty = !isUndefined(accessLevel)
    ? { [accessLevelPropertyName]: accessLevel }
    : {};

  return {
    [basePropertyName]: {
      ...accessLevelProperty,
      ...otherProperties,
    },
  };
};

export const groupLinkRequestFormatter = baseRequestFormatter(
  GROUP_LINK_BASE_PROPERTY_NAME,
  GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME,
);
