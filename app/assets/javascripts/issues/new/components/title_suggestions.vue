<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import query from '../queries/issues.query.graphql';
import TitleSuggestionsItem from './title_suggestions_item.vue';

export default {
  components: {
    HelpIcon,
    TitleSuggestionsItem,
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
      return this.helpText || this.$options.helpText;
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
  helpText: __(
    'These existing issues have a similar title. It might be better to comment there instead of creating another similar issue.',
  ),
};
</script>

<template>
  <div v-show="showSuggestions" class="form-group">
    <div v-once class="gl-pb-3">
      {{ suggestionsTitle }}
      <help-icon v-gl-tooltip.bottom :title="helpIconTitle" :aria-label="helpIconTitle" />
    </div>
    <ul class="gl-m-0 gl-list-none gl-p-0">
      <li
        v-for="(suggestion, index) in issues"
        :key="suggestion.id"
        :class="{
          'gl-mb-3': index !== issues.length - 1,
        }"
      >
        <title-suggestions-item :suggestion="suggestion" />
      </li>
    </ul>
  </div>
</template>
