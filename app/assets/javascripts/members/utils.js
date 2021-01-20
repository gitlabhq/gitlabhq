import { __ } from '~/locale';
import { getParameterByName } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import { FIELDS, DEFAULT_SORT } from './constants';

export const generateBadges = (member, isCurrentUser) => [
  {
    show: isCurrentUser,
    text: __("It's you"),
    variant: 'success',
  },
  {
    show: member.user?.blocked,
    text: __('Blocked'),
    variant: 'danger',
  },
  {
    show: member.user?.twoFactorEnabled,
    text: __('2FA'),
    variant: 'info',
  },
];

export const isGroup = (member) => {
  return Boolean(member.sharedWithGroup);
};

export const isDirectMember = (member, sourceId) => {
  return isGroup(member) || member.source?.id === sourceId;
};

export const isCurrentUser = (member, currentUserId) => {
  return member.user?.id === currentUserId;
};

export const canRemove = (member, sourceId) => {
  return isDirectMember(member, sourceId) && member.canRemove;
};

export const canResend = (member) => {
  return Boolean(member.invite?.canResend);
};

export const canUpdate = (member, currentUserId, sourceId) => {
  return (
    !isCurrentUser(member, currentUserId) && isDirectMember(member, sourceId) && member.canUpdate
  );
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

// Defined in `ee/app/assets/javascripts/vue_shared/components/members/utils.js`
export const canOverride = () => false;
