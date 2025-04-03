<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import emptySearchSVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'GlobalSearchResultsError',
  i18n: {
    title: s__('SearchError|A problem has occurred'),
    description: s__(
      'SearchError|To resolve the problem, check the query syntax and try again. %{linkStart}What is the supported syntax%{linkEnd}',
    ),
    emptyStateDescription: s__('SearchError|No results found'),
  },
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  computed: {
    syntaxHelplink() {
      return helpPagePath('user/search/exact_code_search.md', { anchor: 'syntax' });
    },
  },
  emptySearchSVG,
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="$options.emptySearchSVG"
    :description="$options.i18n.emptyStateDescription"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.description">
        <template #link="{ content }">
          <gl-link :href="syntaxHelplink" target="_blank" data-testid="syntax-link">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
