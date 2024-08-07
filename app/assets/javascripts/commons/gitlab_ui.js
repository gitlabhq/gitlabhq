import applyGitLabUIConfig from '@gitlab/ui/dist/config';
import { __, s__, n__ } from '~/locale';
import {
  PREV,
  NEXT,
  LABEL_FIRST_PAGE,
  LABEL_PREV_PAGE,
  LABEL_NEXT_PAGE,
  LABEL_LAST_PAGE,
} from '~/vue_shared/components/pagination/constants';

applyGitLabUIConfig({
  translations: {
    'GlSearchBoxByType.input.placeholder': __('Search'),
    'GlSearchBoxByType.clearButtonTitle': __('Clear'),
    'GlSorting.sortAscending': __('Sort direction: Ascending'),
    'GlSorting.sortDescending': __('Sort direction: Descending'),
    'ClearIconButton.title': __('Clear'),
    'GlKeysetPagination.prevText': PREV,
    'GlKeysetPagination.navigationLabel': s__('Pagination|Pagination'),
    'GlKeysetPagination.nextText': NEXT,

    'GlPagination.labelFirstPage': LABEL_FIRST_PAGE,
    'GlPagination.labelLastPage': LABEL_LAST_PAGE,
    'GlPagination.labelNextPage': LABEL_NEXT_PAGE,
    'GlPagination.labelPage': s__('Pagination|Go to page %{page}'),
    'GlPagination.labelPrevPage': LABEL_PREV_PAGE,
    'GlPagination.nextText': NEXT,
    'GlPagination.prevText': PREV,

    'GlCollapsibleListbox.srOnlyResultsLabel': (count) => n__('%d result', '%d results', count),
  },
  useImprovedHideHeuristics: Boolean(gon?.features?.improvedHideHeuristics),
});
