<script>
import { GlButton, GlDropdownItem, GlSearchBoxByType, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { debounce } from 'lodash';
import { REF_TYPE_TAGS, SEARCH_DEBOUNCE_MS } from '~/ref/constants';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlDropdownItem,
    GlSearchBoxByType,
    GlSprintf,
  },
  model: {
    prop: 'query',
    event: 'change',
  },
  props: {
    query: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return { tagName: '' };
  },
  computed: {
    ...mapState('ref', ['matches']),
    ...mapState('editNew', ['projectId', 'release']),
    tags() {
      return this.matches?.tags?.list || [];
    },
    createText() {
      return this.query ? this.$options.i18n.createTag : this.$options.i18n.typeNew;
    },
    selectedNotShown() {
      return this.release.tagName && !this.tags.some((tag) => tag.name === this.release.tagName);
    },
  },
  created() {
    this.debouncedSearch = debounce(this.search, SEARCH_DEBOUNCE_MS);
  },
  mounted() {
    this.setProjectId(this.projectId);
    this.setEnabledRefTypes([REF_TYPE_TAGS]);
    this.search(this.query);
  },
  methods: {
    ...mapActions('ref', ['setEnabledRefTypes', 'setProjectId', 'search']),
    onSearchBoxInput(searchQuery = '') {
      const query = searchQuery.trim();
      this.$emit('change', query);
      this.debouncedSearch(query);
    },
    selected(tagName) {
      return (this.release?.tagName ?? '') === tagName;
    },
  },
  i18n: {
    noResults: __('No results found'),
    createTag: s__('Release|Create tag %{tag}'),
    typeNew: s__('Release|Or type a new tag name'),
  },
};
</script>
<template>
  <div data-testid="tag-name-search">
    <gl-search-box-by-type
      :value="query"
      class="gl-border-b-1 gl-border-dropdown gl-border-b-solid"
      borderless
      autofocus
      @input="onSearchBoxInput"
    />
    <div class="release-tag-list gl-overflow-y-auto">
      <div v-if="tags.length || release.tagName">
        <gl-dropdown-item v-if="selectedNotShown" is-checked is-check-item class="gl-list-none">
          {{ release.tagName }}
        </gl-dropdown-item>
        <gl-dropdown-item
          v-for="tag in tags"
          :key="tag.name"
          :is-checked="selected(tag.name)"
          is-check-item
          class="gl-list-none"
          @click="$emit('select', tag.name)"
        >
          {{ tag.name }}
        </gl-dropdown-item>
      </div>
      <div v-else class="gl-my-5 gl-flex gl-justify-center gl-text-base gl-text-subtle">
        {{ $options.i18n.noResults }}
      </div>
    </div>
    <div class="gl-border-t-1 gl-border-dropdown gl-py-3 gl-border-t-solid">
      <gl-button
        category="tertiary"
        class="!gl-justify-start !gl-rounded-none"
        block
        :disabled="!query"
        @click="$emit('create', query)"
      >
        <gl-sprintf :message="createText">
          <template #tag>
            <span class="gl-font-bold">{{ query }}</span>
          </template>
        </gl-sprintf>
      </gl-button>
    </div>
  </div>
</template>
