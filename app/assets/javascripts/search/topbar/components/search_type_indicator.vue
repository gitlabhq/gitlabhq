<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { GlSprintf, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  ZOEKT_SEARCH_TYPE,
  ADVANCED_SEARCH_TYPE,
  BASIC_SEARCH_TYPE,
  SEARCH_LEVEL_PROJECT,
  SEARCH_LEVEL_GLOBAL,
  SEARCH_LEVEL_GROUP,
} from '~/search/store/constants';

import { SCOPE_BLOB } from '../../sidebar/constants';

export default {
  name: 'SearchTypeIndicator',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    zoekt_enabled: s__(
      'GlobalSearch|%{linkStart}Exact code search (powered by Zoekt)%{linkEnd} is enabled.',
    ),
    zoekt_disabled: s__(
      'GlobalSearch|%{linkStart}Exact code search (powered by Zoekt)%{linkEnd} is disabled since %{ref_elem} is not the default branch. %{docs_link}',
    ),
    advanced_enabled: __('%{linkStart}Advanced search%{linkEnd} is enabled.'),
    advanced_disabled: __(
      '%{linkStart}Advanced search%{linkEnd} is disabled since %{ref_elem} is not the default branch. %{docs_link}',
    ),
    more: __('Learn more.'),
  },
  zoektHelpUrl: helpPagePath('user/search/exact_code_search.md'),
  zoektSyntaxHelpUrl: helpPagePath('user/search/exact_code_search.md', {
    anchor: 'syntax',
  }),
  advancedSearchHelpUrl: helpPagePath('user/search/advanced_search.md'),
  advancedSearchSyntaxHelpUrl: helpPagePath('user/search/advanced_search.md', {
    anchor: 'syntax',
  }),
  components: {
    GlSprintf,
    GlLink,
  },
  computed: {
    ...mapState([
      'searchType',
      'advancedSearchAvailable',
      'zoektAvailable',
      'defaultBranchName',
      'query',
      'searchLevel',
      'query',
    ]),
    ...mapGetters(['currentScope']),
    isZoekt() {
      return this.searchType === ZOEKT_SEARCH_TYPE && this.currentScope === SCOPE_BLOB;
    },
    isAdvancedSearch() {
      return (
        this.searchType === ADVANCED_SEARCH_TYPE ||
        (this.searchType === ZOEKT_SEARCH_TYPE && this.currentScope !== SCOPE_BLOB)
      );
    },
    searchTypeTestId() {
      if (this.isZoekt) {
        return ZOEKT_SEARCH_TYPE;
      }
      if (this.isAdvancedSearch) {
        return ADVANCED_SEARCH_TYPE;
      }

      return BASIC_SEARCH_TYPE;
    },
    searchTypeAvailableTestId() {
      if (this.zoektAvailable) {
        return ZOEKT_SEARCH_TYPE;
      }

      return ADVANCED_SEARCH_TYPE;
    },
    useAdvancedOrZoekt() {
      const repoRef = this.query.repository_ref;
      switch (this.searchLevel) {
        case SEARCH_LEVEL_GLOBAL:
        case SEARCH_LEVEL_GROUP:
          return true;
        case SEARCH_LEVEL_PROJECT: {
          if (this.currentScope !== SCOPE_BLOB) {
            return true;
          }
          return !repoRef || repoRef === this.defaultBranchName;
        }
        default:
          return false;
      }
    },
    isFallBacktoBasicSearch() {
      return !this.useAdvancedOrZoekt && (this.advancedSearchAvailable || this.zoektAvailable);
    },
    isBasicSearch() {
      return this.searchType === BASIC_SEARCH_TYPE;
    },
    disabledMessage() {
      return this.zoektAvailable
        ? this.$options.i18n.zoekt_disabled
        : this.$options.i18n.advanced_disabled;
    },
    helpUrl() {
      return this.isZoekt ? this.$options.zoektHelpUrl : this.$options.advancedSearchHelpUrl;
    },
    enabledMessage() {
      return this.isZoekt ? this.$options.i18n.zoekt_enabled : this.$options.i18n.advanced_enabled;
    },
    syntaxHelpUrl() {
      return this.zoektAvailable
        ? this.$options.zoektSyntaxHelpUrl
        : this.$options.advancedSearchSyntaxHelpUrl;
    },
  },
};
</script>

<template>
  <div class="gl-inline gl-text-subtle">
    <div v-if="isBasicSearch" data-testid="basic">
      <div v-if="isFallBacktoBasicSearch" :data-testid="`${searchTypeAvailableTestId}-disabled`">
        <gl-sprintf :message="disabledMessage">
          <template #link="{ content }">
            <gl-link :href="helpUrl" target="_blank" data-testid="docs-link">{{ content }}</gl-link>
          </template>
          <template #ref_elem>
            <code v-gl-tooltip :title="query.repository_ref">{{ query.repository_ref }}</code>
          </template>
          <template #docs_link>
            <gl-link :href="syntaxHelpUrl" target="_blank" data-testid="syntax-docs-link"
              >{{ $options.i18n.more }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </div>
    <div v-else :data-testid="`${searchTypeTestId}-enabled`" class="gl-inline">
      <gl-sprintf :message="enabledMessage">
        <template #link="{ content }">
          <gl-link :href="helpUrl" target="_blank" data-testid="docs-link">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
