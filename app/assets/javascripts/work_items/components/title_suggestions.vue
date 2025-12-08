<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import query from '../graphql/issues.query.graphql';
import TitleSuggestionsItem from './title_suggestions_item.vue';

export default {
  name: 'TitleSuggestions',
  components: {
    TitleSuggestionsItem,
    CrudComponent,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    search: {
      type: String,
      required: true,
    },
    helpText: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    issues: {
      query,
      debounce: 1000,
      skip() {
        return this.isSearchEmpty;
      },
      update: (data) => data?.project?.issues?.edges.map(({ node }) => node) ?? [],
      variables() {
        return {
          fullPath: this.projectPath,
          search: this.search,
        };
      },
    },
  },
  data() {
    return {
      issues: [],
      loading: 0,
    };
  },
  computed: {
    isSearchEmpty() {
      return !this.search.length;
    },
    showSuggestions() {
      return !this.isSearchEmpty && this.issues.length && !this.loading;
    },
    helpIconTitle() {
      return this.helpText || this.$options.i18n.helpText;
    },
    suggestionsTitle() {
      return this.title || __('Similar issues');
    },
  },
  watch: {
    search() {
      if (this.isSearchEmpty) {
        this.issues = [];
      }
    },
  },
  i18n: {
    helpText: __(
      'These existing issues have a similar title. It might be better to comment there instead of creating another similar issue.',
    ),
  },
};
</script>

<template>
  <crud-component
    v-show="showSuggestions"
    is-collapsible
    persist-collapsed-state
    anchor-id="work-item-similar-items"
    :title="suggestionsTitle"
    :count="issues.length"
    class="!-gl-mt-4 gl-mb-5"
  >
    <div
      class="gl-mx-3 gl-mt-3 gl-rounded-base gl-bg-strong gl-px-3 gl-py-2 gl-text-sm gl-font-semibold gl-text-subtle"
    >
      {{ helpIconTitle }}
    </div>
    <ul class="content-list">
      <li
        v-for="(suggestion, index) in issues"
        :key="suggestion.id"
        :class="{
          'gl-mb-4': index !== issues.length - 1,
        }"
      >
        <title-suggestions-item :suggestion="suggestion" />
      </li>
    </ul>
  </crud-component>
</template>
