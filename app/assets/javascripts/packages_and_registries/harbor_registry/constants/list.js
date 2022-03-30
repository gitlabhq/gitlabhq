import { s__, __, n__ } from '~/locale';
import { NAME_SORT_FIELD } from './common';

//  Translations strings

export const HARBOR_REGISTRY_TITLE = s__('HarborRegistry|Harbor Registry');

export const CONNECTION_ERROR_TITLE = s__('HarborRegistry|Harbor connection error');
export const CONNECTION_ERROR_MESSAGE = s__(
  `HarborRegistry|We are having trouble connecting to the Harbor Registry. Please try refreshing the page. If this error persists, please review  %{docLinkStart}the troubleshooting documentation%{docLinkEnd}.`,
);
export const LIST_INTRO_TEXT = s__(
  `HarborRegistry|With the Harbor Registry, every project can have its own space to store images. %{docLinkStart}More information%{docLinkEnd}`,
);

export const imagesCountInfoText = (count) => {
  return n__(
    'HarborRegistry|%{count} Image repository',
    'HarborRegistry|%{count} Image repositories',
    count,
  );
};

export const EMPTY_RESULT_TITLE = s__('HarborRegistry|Sorry, your filter produced no results.');
export const EMPTY_RESULT_MESSAGE = s__(
  'HarborRegistry|To widen your search, change or remove the filters above.',
);

export const SORT_FIELDS = [
  { orderBy: 'UPDATED', label: __('Updated') },
  { orderBy: 'CREATED', label: __('Created') },
  NAME_SORT_FIELD,
];
