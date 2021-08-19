import { s__ } from '~/locale';
import {
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
    default:
      return null;
  }
};
