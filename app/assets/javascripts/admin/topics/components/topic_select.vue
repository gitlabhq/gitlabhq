<script>
import { GlAvatarLabeled, GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__, n__ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';

export default {
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    selectedTopic: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    labelText: {
      type: String,
      required: false,
      default: null,
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
        return data.topics?.nodes || [];
      },
      debounce: 250,
    },
  },
  data() {
    return {
      topics: [],
      search: '',
      selected: null,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.topics.loading;
    },
    dropdownText() {
      if (Object.keys(this.selectedTopic).length) {
        return this.selectedTopic.name;
      }

      return this.$options.i18n.dropdownText;
    },
    items() {
      return this.topics.map(({ id, title, name, avatarUrl }) => ({
        value: id,
        text: title,
        secondaryText: name,
        icon: avatarUrl,
      }));
    },
    searchSummary() {
      return n__('TopicSelect|%d topic found', 'TopicSelect|%d topics found', this.topics.length);
    },
    labelId() {
      if (!this.labelText) {
        return null;
      }

      return uniqueId('topic-listbox-label-');
    },
  },
  methods: {
    onSelect(topicId) {
      const topicObj = this.topics.find((topic) => topic.id === topicId);

      if (!topicObj) return;

      this.$emit('click', topicObj);
    },
    onSearch(query) {
      this.search = query;
    },
  },
  i18n: {
    dropdownText: s__('TopicSelect|Select a topic'),
    searchPlaceholder: s__('TopicSelect|Search topics'),
    emptySearchResult: s__('TopicSelect|No matching results'),
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-form-group :id="labelId">
    <template #label>
      {{ labelText }}
    </template>
    <gl-collapsible-listbox
      v-model="selected"
      block
      searchable
      is-check-centered
      :items="items"
      :toggle-text="dropdownText"
      :searching="loading"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :no-results-text="$options.i18n.emptySearchResult"
      :toggle-aria-labelled-by="labelId"
      @select="onSelect"
      @search="onSearch"
    >
      <template #list-item="{ item: { text, secondaryText, icon } }">
        <gl-avatar-labeled
          :label="text"
          :sub-label="secondaryText"
          :src="icon"
          :entity-name="secondaryText"
          :size="32"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
      </template>
      <template #search-summary-sr-only>
        {{ searchSummary }}
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
