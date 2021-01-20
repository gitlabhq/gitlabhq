import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const PACKAGE_SETTINGS_HEADER = s__('PackageRegistry|Package Registry');
export const PACKAGE_SETTINGS_DESCRIPTION = s__(
  'PackageRegistry|GitLab Packages allows organizations to utilize GitLab as a private repository for a variety of common package formats. %{linkStart}More Information%{linkEnd}',
);

export const PACKAGES_DOCS_PATH = helpPagePath('user/packages');
