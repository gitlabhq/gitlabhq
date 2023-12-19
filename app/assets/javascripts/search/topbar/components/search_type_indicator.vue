<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlSprintf, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  ZOEKT_SEARCH_TYPE,
  ADVANCED_SEARCH_TYPE,
  BASIC_SEARCH_TYPE,
  SEARCH_LEVEL_PROJECT,
} from '~/search/store/constants';
import {
  ZOEKT_HELP_PAGE,
  ADVANCED_SEARCH_HELP_PAGE,
  ADVANCED_SEARCH_SYNTAX_HELP_ANCHOR,
  ZOEKT_HELP_PAGE_SYNTAX_ANCHOR,
} from '../constants';

export default {
  name: 'SearchTypeIndicator',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    zoekt_enabled: s__(
      'GlobalSearch|%{linkStart}Exact code search (powered by Zoekt)%{linkEnd} is enabled',
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
  components: {
    GlSprintf,
    GlLink,
  },
  computed: {
    ...mapState(['searchType', 'defaultBranchName', 'query', 'searchLevel']),
    zoektHelpUrl() {
      return helpPagePath(ZOEKT_HELP_PAGE);
    },
    zoektSyntaxHelpUrl() {
      return helpPagePath(ZOEKT_HELP_PAGE, {
        anchor: ZOEKT_HELP_PAGE_SYNTAX_ANCHOR,
      });
    },
    advancedSearchHelpUrl() {
      return helpPagePath(ADVANCED_SEARCH_HELP_PAGE);
    },
    advancedSearchSyntaxHelpUrl() {
      return helpPagePath(ADVANCED_SEARCH_HELP_PAGE, {
        anchor: ADVANCED_SEARCH_SYNTAX_HELP_ANCHOR,
      });
    },
    isZoekt() {
      return this.searchType === ZOEKT_SEARCH_TYPE;
    },
    isAdvancedSearch() {
      return this.searchType === ADVANCED_SEARCH_TYPE;
    },
    isEnabled() {
      if (this.searchLevel !== SEARCH_LEVEL_PROJECT) {
        return true;
      }

      return !this.query.repository_ref || this.query.repository_ref === this.defaultBranchName;
    },
    isBasicSearch() {
      return this.searchType === BASIC_SEARCH_TYPE;
    },
    disabledMessage() {
      return this.isZoekt
        ? this.$options.i18n.zoekt_disabled
        : this.$options.i18n.advanced_disabled;
    },
    helpUrl() {
      return this.isZoekt ? this.zoektHelpUrl : this.advancedSearchHelpUrl;
    },
    enabledMessage() {
      return this.isZoekt ? this.$options.i18n.zoekt_enabled : this.$options.i18n.advanced_enabled;
    },
    syntaxHelpUrl() {
      return this.isZoekt ? this.zoektSyntaxHelpUrl : this.advancedSearchSyntaxHelpUrl;
    },
  },
};
</script>

<template>
  <div class="gl-text-gray-600">
    <div v-if="isBasicSearch" data-testid="basic">&nbsp;</div>
    <div v-else-if="isEnabled" :data-testid="`${searchType}-enabled`">
      <gl-sprintf :message="enabledMessage">
        <template #link="{ content }">
          <gl-link :href="helpUrl" target="_blank" data-testid="docs-link">{{ content }} </gl-link>
        </template>
      </gl-sprintf>
    </div>
    <div v-else :data-testid="`${searchType}-disabled`">
      <gl-sprintf :message="disabledMessage">
        <template #link="{ content }">
          <gl-link :href="helpUrl" target="_blank" data-testid="docs-link">{{ content }} </gl-link>
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
</template>
