import { capitalize } from 'lodash';
import { s__ } from '~/locale';
import {
  GRAPHQL_PAGE_SIZE,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_PYPI,
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_RUBYGEMS,
  PACKAGE_TYPE_GENERIC,
  PACKAGE_TYPE_DEBIAN,
  PACKAGE_TYPE_HELM,
  PACKAGE_TYPE_ML_MODEL,
  LIST_KEY_PROJECT,
  SORT_FIELDS,
} from './constants';

export const getPackageTypeLabel = (packageType) => {
  switch (packageType) {
    case PACKAGE_TYPE_CONAN:
      return s__('PackageRegistry|Conan');
    case PACKAGE_TYPE_MAVEN:
      return s__('PackageRegistry|Maven');
    case PACKAGE_TYPE_NPM:
      return s__('PackageRegistry|npm');
    case PACKAGE_TYPE_NUGET:
      return s__('PackageRegistry|NuGet');
    case PACKAGE_TYPE_PYPI:
      return s__('PackageRegistry|PyPI');
    case PACKAGE_TYPE_RUBYGEMS:
      return s__('PackageRegistry|RubyGems');
    case PACKAGE_TYPE_COMPOSER:
      return s__('PackageRegistry|Composer');
    case PACKAGE_TYPE_GENERIC:
      return s__('PackageRegistry|Generic');
    case PACKAGE_TYPE_DEBIAN:
      return s__('PackageRegistry|Debian');
    case PACKAGE_TYPE_HELM:
      return s__('PackageRegistry|Helm');
    case PACKAGE_TYPE_ML_MODEL:
      return s__('PackageRegistry|MlModel');
    default:
      return null;
  }
};

export const packageTypeToTrackCategory = (type) => `UI::${capitalize(type)}Packages`;

export const sortableFields = (isGroupPage) =>
  SORT_FIELDS.filter((f) => f.orderBy !== LIST_KEY_PROJECT || isGroupPage);

export const getNextPageParams = (cursor) => ({
  after: cursor,
  first: GRAPHQL_PAGE_SIZE,
});

export const getPreviousPageParams = (cursor) => ({
  first: null,
  before: cursor,
  last: GRAPHQL_PAGE_SIZE,
});

export const getPageParams = (pageInfo = {}) => {
  if (pageInfo.before) {
    return getPreviousPageParams(pageInfo.before);
  }

  if (pageInfo.after) {
    return getNextPageParams(pageInfo.after);
  }

  return {};
};
