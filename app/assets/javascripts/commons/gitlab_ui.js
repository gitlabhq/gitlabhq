import applyGitLabUIConfig from '@gitlab/ui/dist/config';
import { __ } from '~/locale';

applyGitLabUIConfig({
  translations: {
    'GlSearchBoxByType.input.placeholder': __('Search'),
    'GlSearchBoxByType.clearButtonTitle': __('Clear'),
    'ClearIconButton.title': __('Clear'),
  },
});
