import { __, s__ } from '~/locale';

export const BRANCHES = s__('Commit|Branches');

export const TAGS = s__('Commit|Tags');

export const CONTAINING_COMMIT = s__('Commit|containing commit');

export const FETCH_CONTAINING_REFS_EVENT = 'fetch-containing-refs';

export const FETCH_COMMIT_REFERENCES_ERROR = s__(
  'Commit|There was an error fetching the commit references. Please try again later.',
);

export const BRANCHES_REF_TYPE = 'heads';

export const TAGS_REF_TYPE = 'tags';

export const EMPTY_BRANCHES_MESSAGE = __('No related branches found');
export const EMPTY_TAGS_MESSAGE = __('No related tags found');
