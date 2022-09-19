<script>
import {
  GlAvatarLabeled,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';

export default {
  components: {
    GlAvatarLabeled,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlSearchBoxByType,
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
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.topics.loading;
    },
    isResultEmpty() {
      return this.topics.length === 0;
    },
    dropdownText() {
      if (Object.keys(this.selectedTopic).length) {
        return this.selectedTopic.name;
      }

      return this.$options.i18n.dropdownText;
    },
  },
  methods: {
    selectTopic(topic) {
      this.$emit('click', topic);
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
  <div>
    <label v-if="labelText">{{ labelText }}</label>
    <gl-dropdown block :text="dropdownText">
      <gl-search-box-by-type
        v-model="search"
        :is-loading="loading"
        :placeholder="$options.i18n.searchPlaceholder"
      />
      <gl-dropdown-item v-for="topic in topics" :key="topic.id" @click="selectTopic(topic)">
        <gl-avatar-labeled
          :label="topic.title"
          :sub-label="topic.name"
          :src="topic.avatarUrl"
          :entity-name="topic.name"
          :size="32"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        />
      </gl-dropdown-item>
      <gl-dropdown-text v-if="isResultEmpty && !loading">
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
    </gl-dropdown>
  </div>
</template>
