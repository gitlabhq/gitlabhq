import applyGitLabUIConfig from '@gitlab/ui/dist/config';
import { __ } from '~/locale';

applyGitLabUIConfig({
  translations: {
    'GlSearchBoxByType.input.placeholder': __('Search'),
    'GlSearchBoxByType.clearButtonTitle': __('Clear'),
    'GlSorting.sortAscending': __('Sort direction: Ascending'),
    'GlSorting.sortDescending': __('Sort direction: Descending'),
    'ClearIconButton.title': __('Clear'),
  },
});
