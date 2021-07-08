import { s__ } from '~/locale';
import { PackageType, TrackingCategories } from './constants';

export const packageTypeToTrackCategory = (type) =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `UI::${TrackingCategories[type]}`;

export const beautifyPath = (path) => (path ? path.split('/').join(' / ') : '');

export const getPackageTypeLabel = (packageType) => {
  switch (packageType) {
    case PackageType.CONAN:
      return s__('PackageRegistry|Conan');
    case PackageType.MAVEN:
      return s__('PackageRegistry|Maven');
    case PackageType.NPM:
      return s__('PackageRegistry|npm');
    case PackageType.NUGET:
      return s__('PackageRegistry|NuGet');
    case PackageType.PYPI:
      return s__('PackageRegistry|PyPI');
    case PackageType.RUBYGEMS:
      return s__('PackageRegistry|RubyGems');
    case PackageType.COMPOSER:
      return s__('PackageRegistry|Composer');
    case PackageType.GENERIC:
      return s__('PackageRegistry|Generic');
    case PackageType.DEBIAN:
      return s__('PackageRegistry|Debian');
    case PackageType.HELM:
      return s__('PackageRegistry|Helm');
    default:
      return null;
  }
};

export const getCommitLink = ({ project_path: projectPath, pipeline = {} }, isGroup = false) => {
  if (isGroup) {
    return `/${projectPath}/commit/${pipeline.sha}`;
  }

  return `../commit/${pipeline.sha}`;
};
