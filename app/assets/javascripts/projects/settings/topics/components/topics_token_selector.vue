<script>
import { GlTokenSelector, GlAvatarLabeled, GlFormGroup, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';

export default {
  components: {
    GlTokenSelector,
    GlAvatarLabeled,
    GlFormGroup,
    GlLink,
    GlSprintf,
  },
  i18n: {
    topicsTitle: s__('ProjectSettings|Project topics'),
    topicsHelpText: s__(
      'ProjectSettings|Topics are publicly visible even on private projects. Do not include sensitive information in topic names. %{linkStart}Learn more%{linkEnd}.',
    ),
    placeholder: s__('ProjectSettings|Search for topic'),
  },
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
    organizationId: {
      type: String,
      required: true,
    },
  },
  apollo: {
    topics: {
      query: searchProjectTopics,
      variables() {
        return {
          search: this.search,
          organizationId: convertToGraphQLId(TYPE_ORGANIZATION, this.organizationId),
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
    topicsHelpUrl() {
      return helpPagePath('user/project/project_topics');
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
      const uniqueTokens = Array.from(new Map(tokens.map((item) => [item.name, item])).values());

      this.selectedTokens = uniqueTokens;

      this.$emit('update', this.selectedTokens);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>
<template>
  <gl-form-group id="project_topics" :label="$options.i18n.topicsTitle">
    <gl-token-selector
      ref="tokenSelector"
      v-model="selectedTokens"
      :dropdown-items="topics"
      :loading="loading"
      allow-user-defined-tokens
      show-add-new-always
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
    <template #description>
      <gl-sprintf :message="$options.i18n.topicsHelpText">
        <template #link="{ content }">
          <gl-link :href="topicsHelpUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-form-group>
</template>
