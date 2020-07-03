<script>
import { GlButton } from '@gitlab/ui';
import TagsListRow from './tags_list_row.vue';
import { REMOVE_TAGS_BUTTON_TITLE, TAGS_LIST_TITLE } from '../../constants/index';

export default {
  components: {
    GlButton,
    TagsListRow,
  },
  props: {
    tags: {
      type: Array,
      required: false,
      default: () => [],
    },
    isDesktop: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  i18n: {
    REMOVE_TAGS_BUTTON_TITLE,
    TAGS_LIST_TITLE,
  },
  data() {
    return {
      selectedItems: {},
    };
  },
  computed: {
    hasSelectedItems() {
      return this.tags.some(tag => this.selectedItems[tag.name]);
    },
  },
  methods: {
    updateSelectedItems(name) {
      this.$set(this.selectedItems, name, !this.selectedItems[name]);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-mb-3">
      <h5 data-testid="list-title">
        {{ $options.i18n.TAGS_LIST_TITLE }}
      </h5>

      <gl-button
        v-if="isDesktop"
        :disabled="!hasSelectedItems"
        category="secondary"
        variant="danger"
        @click="$emit('delete', selectedItems)"
      >
        {{ $options.i18n.REMOVE_TAGS_BUTTON_TITLE }}
      </gl-button>
    </div>
    <tags-list-row
      v-for="(tag, index) in tags"
      :key="tag.path"
      :tag="tag"
      :first="index === 0"
      :last="index === tags.length - 1"
      :selected="selectedItems[tag.name]"
      :is-desktop="isDesktop"
      @select="updateSelectedItems(tag.name)"
      @delete="$emit('delete', { [tag.name]: true })"
    />
  </div>
</template>
