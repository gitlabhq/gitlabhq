import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

export const PACKAGE_SETTINGS_HEADER = s__('PackageRegistry|Duplicate packages');
export const PACKAGE_SETTINGS_DESCRIPTION = s__(
  'PackageRegistry|Allow packages with the same name and version to be uploaded to the registry. The newest version of a package is always used when installing.',
);
export const PACKAGE_FORMATS_TABLE_HEADER = s__('PackageRegistry|Package formats');
export const MAVEN_PACKAGE_FORMAT = s__('PackageRegistry|Maven');
export const GENERIC_PACKAGE_FORMAT = s__('PackageRegistry|Generic');

export const DUPLICATES_TOGGLE_LABEL = s__('PackageRegistry|Allow duplicates');
export const DUPLICATES_SETTING_EXCEPTION_TITLE = __('Exceptions');
export const DUPLICATES_SETTINGS_EXCEPTION_LEGEND = s__(
  'PackageRegistry|Publish packages if their name or version matches this regex.',
);

export const DEPENDENCY_PROXY_HEADER = s__('DependencyProxy|Dependency Proxy');
export const DEPENDENCY_PROXY_DESCRIPTION = s__(
  'DependencyProxy|Enable the Dependency Proxy and settings for clearing the cache.',
);

// Parameters

export const PACKAGES_DOCS_PATH = helpPagePath('user/packages/index');
export const MAVEN_DUPLICATES_ALLOWED = 'mavenDuplicatesAllowed';
export const MAVEN_DUPLICATE_EXCEPTION_REGEX = 'mavenDuplicateExceptionRegex';

export const DEPENDENCY_PROXY_DOCS_PATH = helpPagePath('user/packages/dependency_proxy/index');
