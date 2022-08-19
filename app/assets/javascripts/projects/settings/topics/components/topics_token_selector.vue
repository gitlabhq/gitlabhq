<script>
import { GlTokenSelector, GlAvatarLabeled } from '@gitlab/ui';
import { s__ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';

export default {
  components: {
    GlTokenSelector,
    GlAvatarLabeled,
  },
  i18n: {
    placeholder: s__('ProjectSettings|Search for topic'),
  },
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    topics: {
      query: searchProjectTopics,
      variables() {
        return {
          search: this.search,
        };
      },
      update(data) {
        return (
          data.topics?.nodes.filter(
            (topic) => !this.selectedTokens.some((token) => token.name === topic.name),
          ) || []
        );
      },
      debounce: 250,
    },
  },
  data() {
    return {
      topics: [],
      selectedTokens: this.selected,
      search: '',
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.topics.loading;
    },
    placeholderText() {
      return this.selectedTokens.length ? '' : this.$options.i18n.placeholder;
    },
  },
  methods: {
    handleEnter(event) {
      // Prevent form from submitting when adding a token
      if (event.target.value !== '') {
        event.preventDefault();
      }
    },
    filterTopics(searchTerm) {
      this.search = searchTerm;
    },
    onTokensUpdate(tokens) {
      this.$emit('update', tokens);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>
<template>
  <gl-token-selector
    ref="tokenSelector"
    v-model="selectedTokens"
    :dropdown-items="topics"
    :loading="loading"
    allow-user-defined-tokens
    :placeholder="placeholderText"
    @keydown.enter="handleEnter"
    @text-input="filterTopics"
    @input="onTokensUpdate"
  >
    <template #dropdown-item-content="{ dropdownItem }">
      <gl-avatar-labeled
        :src="dropdownItem.avatarUrl"
        :entity-name="dropdownItem.name"
        :label="dropdownItem.title"
        :size="32"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
      />
    </template>
  </gl-token-selector>
</template>
