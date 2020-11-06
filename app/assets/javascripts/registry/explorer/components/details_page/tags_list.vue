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
    isMobile: {
      type: Boolean,
      default: true,
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
    showMultiDeleteButton() {
      return this.tags.some(tag => tag.destroy_path) && !this.isMobile;
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
        v-if="showMultiDeleteButton"
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
      :selected="selectedItems[tag.name]"
      :is-mobile="isMobile"
      @select="updateSelectedItems(tag.name)"
      @delete="$emit('delete', { [tag.name]: true })"
    />
  </div>
</template>
