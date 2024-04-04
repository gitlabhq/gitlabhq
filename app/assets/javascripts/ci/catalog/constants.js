import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export const CATALOG_FEEDBACK_DISMISSED_KEY = 'catalog_feedback_dismissed';

export const SCOPE = {
  all: 'ALL',
  namespaces: 'NAMESPACES',
};

export const VerificationLevel = {
  GITLAB: {
    badgeText: s__('CiCatalog|GitLab-maintained'),
    icon: 'tanuki-verified',
    popoverText: s__('CiCatalog|Created and maintained by %{boldStart}GitLab%{boldEnd}'),
  },
  PARTNER: {
    badgeText: s__('CiCatalog|Partner'),
    icon: 'partner-verified',
    popoverText: s__('CiCatalog|Created and maintained by a %{boldStart}GitLab Partner%{boldEnd}'),
  },
};

export const SORT_OPTION_CREATED = 'CREATED';
export const SORT_OPTION_RELEASED = 'LATEST_RELEASED_AT';
export const SORT_ASC = 'ASC';
export const SORT_DESC = 'DESC';
export const DEFAULT_SORT_VALUE = `${SORT_OPTION_CREATED}_${SORT_DESC}`;

export const COMPONENTS_DOCS_URL = helpPagePath('ci/components/index');
