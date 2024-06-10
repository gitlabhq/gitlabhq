import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export const CATALOG_FEEDBACK_DISMISSED_KEY = 'catalog_feedback_dismissed';

export const SCOPE = {
  all: 'ALL',
  namespaces: 'NAMESPACES',
};

export const SORT_OPTION_CREATED = 'CREATED';
export const SORT_OPTION_POPULARITY = 'USAGE_COUNT';
export const SORT_OPTION_RELEASED = 'LATEST_RELEASED_AT';
export const SORT_OPTION_STAR_COUNT = 'STAR_COUNT';
export const SORT_ASC = 'ASC';
export const SORT_DESC = 'DESC';
export const DEFAULT_SORT_VALUE = `${SORT_OPTION_CREATED}_${SORT_DESC}`;

export const COMPONENTS_DOCS_URL = helpPagePath('ci/components/index');

export const VERIFICATION_LEVEL_GITLAB_MAINTAINED_BADGE_TEXT = s__('CiCatalog|GitLab-maintained');
export const VERIFICATION_LEVEL_GITLAB_MAINTAINED_ICON = 'tanuki-verified';
export const VERIFICATION_LEVEL_GITLAB_MAINTAINED_POPOVER_TEXT = s__(
  'CiCatalog|Created and maintained by %{boldStart}GitLab%{boldEnd}',
);
export const VERIFICATION_LEVEL_GITLAB_PARTNER_MAINTAINED_BADGE_TEXT = s__('CiCatalog|Partner');
export const VERIFICATION_LEVEL_GITLAB_PARTNER_MAINTAINED_ICON = 'partner-verified';
export const VERIFICATION_LEVEL_GITLAB_PARTNER_MAINTAINED_POPOVER_TEXT = s__(
  'CiCatalog|Created and maintained by a %{boldStart}GitLab Partner%{boldEnd}',
);
export const VERIFICATION_LEVEL_UNVERIFIED = 'UNVERIFIED';

export const VERIFICATION_LEVELS = {
  GITLAB_MAINTAINED: {
    badgeText: VERIFICATION_LEVEL_GITLAB_MAINTAINED_BADGE_TEXT,
    icon: VERIFICATION_LEVEL_GITLAB_MAINTAINED_ICON,
    popoverText: VERIFICATION_LEVEL_GITLAB_MAINTAINED_POPOVER_TEXT,
  },
  GITLAB_PARTNER_MAINTAINED: {
    badgeText: VERIFICATION_LEVEL_GITLAB_PARTNER_MAINTAINED_BADGE_TEXT,
    icon: VERIFICATION_LEVEL_GITLAB_PARTNER_MAINTAINED_ICON,
    popoverText: VERIFICATION_LEVEL_GITLAB_PARTNER_MAINTAINED_POPOVER_TEXT,
  },
};
