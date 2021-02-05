<script>
import { GlButton } from '@gitlab/ui';
import { REMOVE_TAGS_BUTTON_TITLE, TAGS_LIST_TITLE } from '../../constants/index';
import TagsListRow from './tags_list_row.vue';

export default {
  name: 'TagsList',
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
    disabled: {
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
      return this.tags.some((tag) => this.selectedItems[tag.name]);
    },
    showMultiDeleteButton() {
      return this.tags.some((tag) => tag.canDelete) && !this.isMobile;
    },
    multiDeleteButtonIsDisabled() {
      return !this.hasSelectedItems || this.disabled;
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
        :disabled="multiDeleteButtonIsDisabled"
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
      :disabled="disabled"
      @select="updateSelectedItems(tag.name)"
      @delete="$emit('delete', { [tag.name]: true })"
    />
  </div>
</template>
