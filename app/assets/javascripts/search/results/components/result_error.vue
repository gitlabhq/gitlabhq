<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import emptySearchSVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { ZOEKT_CONNECTION_ERROR_IDENTIFIER } from '../constants';

export default {
  name: 'GlobalSearchResultsError',
  i18n: {
    title: s__('SearchError|A problem has occurred'),
    description: s__(
      'SearchError|To resolve the problem, check the query syntax and try again. %{linkStart}What is the supported syntax%{linkEnd}',
    ),
    emptyStateDescription: s__('SearchError|No results found'),
    networkDescription: s__('SearchError|Cannot connect to the Zoekt'),
  },
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  props: {
    error: {
      type: Error,
      required: false,
      default: null,
    },
  },
  computed: {
    syntaxHelplink() {
      return helpPagePath('user/search/exact_code_search.md', { anchor: 'syntax' });
    },
    errorType() {
      const errorType = this.error?.graphQLErrors?.[0]?.extensions?.error_type;
      return errorType === ZOEKT_CONNECTION_ERROR_IDENTIFIER ? 'network' : 'default';
    },
    errorTitle() {
      return this.$options.i18n.title;
    },
    errorDescription() {
      if (this.errorType === 'network') {
        return this.$options.i18n.networkDescription;
      }
      return this.$options.i18n.description;
    },
    showSyntaxLink() {
      return this.errorType === 'default';
    },
  },
  emptySearchSVG,
};
</script>

<template>
  <gl-empty-state
    :title="errorTitle"
    :svg-path="$options.emptySearchSVG"
    :description="$options.i18n.emptyStateDescription"
  >
    <template #description>
      <gl-sprintf v-if="showSyntaxLink" :message="errorDescription">
        <template #link="{ content }">
          <gl-link :href="syntaxHelplink" target="_blank" data-testid="syntax-link">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
      <div v-else>{{ errorDescription }}</div>
    </template>
  </gl-empty-state>
</template>
