import { isFinite } from 'lodash';
import {
  SORT_FIELD_MAPPING,
  TOKEN_TYPE_TAG_NAME,
} from '~/packages_and_registries/harbor_registry/constants';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export const extractSortingDetail = (parsedSorting = '') => {
  const [orderBy, sortOrder] = parsedSorting.split('_');
  if (orderBy && sortOrder) {
    return {
      orderBy: SORT_FIELD_MAPPING[orderBy],
      sort: sortOrder.toLowerCase(),
    };
  }

  return {
    orderBy: '',
    sort: '',
  };
};

export const parseFilter = (filters = [], defaultPrefix = '') => {
  /* eslint-disable @gitlab/require-i18n-strings */
  const prefixMap = {
    [FILTERED_SEARCH_TERM]: `${defaultPrefix}=`,
    [TOKEN_TYPE_TAG_NAME]: 'tags=',
  };
  /* eslint-enable @gitlab/require-i18n-strings */
  const filterList = [];
  filters.forEach((i) => {
    if (i.value?.data) {
      const filterVal = i.value?.data;
      const prefix = prefixMap[i.type];
      const filterString = `${prefix}${filterVal}`;

      filterList.push(filterString);
    }
  });

  return filterList.join(',');
};

export const getNameFromParams = (fullName) => {
  const names = fullName.split('/');
  return {
    projectName: names[0] || '',
    imageName: names[1] || '',
  };
};

export const formatPagination = (headers) => {
  const pagination = parseIntPagination(normalizeHeaders(headers)) || {};

  if (pagination.nextPage || pagination.previousPage) {
    pagination.hasNextPage = isFinite(pagination.nextPage);
    pagination.hasPreviousPage = isFinite(pagination.previousPage);
  }

  return pagination;
};

/* eslint-disable @gitlab/require-i18n-strings */
export const dockerBuildCommand = ({ repositoryUrl, harborProjectName, projectName = '' }) => {
  return `docker build -t ${repositoryUrl}/${harborProjectName}/${projectName} .`;
};

export const dockerPushCommand = ({ repositoryUrl, harborProjectName, projectName = '' }) => {
  return `docker push ${repositoryUrl}/${harborProjectName}/${projectName}`;
};

export const dockerLoginCommand = (repositoryUrl) => {
  return `docker login ${repositoryUrl}`;
};

export const artifactPullCommand = ({ repositoryUrl, harborProjectName, imageName, digest }) => {
  return `docker pull ${repositoryUrl}/${harborProjectName}/${imageName}@${digest}`;
};

export const tagPullCommand = ({ repositoryUrl, harborProjectName, imageName, tag }) => {
  return `docker pull ${repositoryUrl}/${harborProjectName}/${imageName}:${tag}`;
};
/* eslint-enable @gitlab/require-i18n-strings */
