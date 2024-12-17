import { __, s__ } from '~/locale';

export const MAX_MILESTONES_TO_DISPLAY = 5;

export const BACK_URL_PARAM = 'back_url';

export const ASSET_LINK_TYPE = Object.freeze({
  OTHER: 'other',
  IMAGE: 'image',
  PACKAGE: 'package',
  RUNBOOK: 'runbook',
});

export const DEFAULT_ASSET_LINK_TYPE = ASSET_LINK_TYPE.OTHER;

export const PAGE_SIZE = 10;

export const ASCENDING_ORDER = 'asc';
export const DESCENDING_ORDER = 'desc';
export const RELEASED_AT = 'released_at';
export const CREATED_AT = 'created_at';

export const SORT_OPTIONS = [
  {
    value: RELEASED_AT,
    text: __('Released date'),
  },
  {
    value: CREATED_AT,
    text: __('Created date'),
  },
];

export const RELEASED_AT_ASC = 'RELEASED_AT_ASC';
export const RELEASED_AT_DESC = 'RELEASED_AT_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CREATED_DESC = 'CREATED_DESC';
export const ALL_SORTS = [RELEASED_AT_ASC, RELEASED_AT_DESC, CREATED_ASC, CREATED_DESC];

export const SORT_MAP = {
  [RELEASED_AT]: {
    [ASCENDING_ORDER]: RELEASED_AT_ASC,
    [DESCENDING_ORDER]: RELEASED_AT_DESC,
  },
  [CREATED_AT]: {
    [ASCENDING_ORDER]: CREATED_ASC,
    [DESCENDING_ORDER]: CREATED_DESC,
  },
};

export const DEFAULT_SORT = RELEASED_AT_DESC;

export const i18n = {
  alertInfoMessage: s__(
    'CiCatalog|To publish CI/CD components to the Catalog, you must use the %{linkStart}release%{linkEnd} keyword in a CI/CD job.',
  ),
  alertInfoPublishMessage: s__('CiCatalog|How do I publish a component?'),
  alertTitle: s__('CiCatalog|Publish the CI/CD components in this project to the CI/CD Catalog'),
  atomFeedBtnTitle: __('Subscribe to releases RSS feed'),
  catalogResourceReleaseBtnTitle: s__(
    "CiCatalog|Use the 'release' keyword in a CI/CD job to publish to the CI/CD Catalog.",
  ),
  defaultReleaseBtnTitle: __('Create a new release'),
  errorMessage: __('An error occurred while fetching the releases. Please try again.'),
  newRelease: __('New release'),
  tagNameIsRequiredMessage: __('Tag name is required.'),
  tagIsAlredyInUseMessage: __('Selected tag is already in use. Choose another option.'),
};

export const CLICK_EXPAND_DEPLOYMENTS_ON_RELEASE_PAGE = 'click_expand_deployments_on_release_page';
export const CLICK_EXPAND_ASSETS_ON_RELEASE_PAGE = 'click_expand_assets_on_release_page';
export const CLICK_ENVIRONMENT_LINK_ON_RELEASE_PAGE = 'click_environment_link_on_release_page';
export const CLICK_DEPLOYMENT_LINK_ON_RELEASE_PAGE = 'click_deployment_link_on_release_page';
