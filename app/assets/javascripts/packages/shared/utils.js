import { s__ } from '~/locale';
import { PackageType, TrackingCategories } from './constants';

export const packageTypeToTrackCategory = type =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `UI::${TrackingCategories[type]}`;

export const beautifyPath = path => (path ? path.split('/').join(' / ') : '');

export const getPackageTypeLabel = packageType => {
  switch (packageType) {
    case PackageType.CONAN:
      return s__('PackageType|Conan');
    case PackageType.MAVEN:
      return s__('PackageType|Maven');
    case PackageType.NPM:
      return s__('PackageType|NPM');
    case PackageType.NUGET:
      return s__('PackageType|NuGet');
    case PackageType.PYPI:
      return s__('PackageType|PyPI');
    case PackageType.COMPOSER:
      return s__('PackageType|Composer');
    case PackageType.GENERIC:
      return s__('PackageType|Generic');
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
