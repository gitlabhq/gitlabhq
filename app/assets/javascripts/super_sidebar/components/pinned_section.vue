<script>
import { GlCollapse, GlIcon } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import { s__ } from '~/locale';
import NavItem from './nav_item.vue';

export default {
  i18n: {
    pinned: s__('Navigation|Pinned'),
    emptyHint: s__('Navigation|Your pinned items appear here.'),
  },
  name: 'PinnedSection',
  components: {
    Draggable,
    GlCollapse,
    GlIcon,
    NavItem,
  },
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      expanded: true,
      draggableItems: this.items,
    };
  },
  computed: {
    collapseIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    itemIds() {
      return this.draggableItems.map((item) => item.id);
    },
  },
  watch: {
    items(newItems) {
      this.draggableItems = newItems;
    },
  },
  methods: {
    handleDrag(event) {
      if (event.oldIndex === event.newIndex) return;
      this.$emit(
        'pin-reorder',
        this.items[event.oldIndex].id,
        this.items[event.newIndex].id,
        event.oldIndex < event.newIndex,
      );
    },
  },
};
</script>

<template>
  <section class="gl-mx-2">
    <a
      href="#"
      class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-py-3 gl-px-0 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-text-decoration-none!"
      @click.prevent="expanded = !expanded"
    >
      <div class="gl-flex-shrink-0 gl-w-6 gl-mx-3">
        <gl-icon name="thumbtack" class="gl-ml-2" />
      </div>

      <span class="gl-font-weight-bold gl-font-sm gl-flex-grow-1">{{ $options.i18n.pinned }}</span>
      <gl-icon :name="collapseIcon" class="gl-mr-3" />
    </a>
    <gl-collapse v-model="expanded">
      <draggable
        v-if="items.length > 0"
        v-model="draggableItems"
        class="gl-p-0 gl-m-0"
        data-testid="pinned-nav-items"
        handle=".draggable-icon"
        tag="ul"
        @end="handleDrag"
      >
        <nav-item
          v-for="item of draggableItems"
          :key="item.id"
          draggable
          :item="item"
          @pin-remove="(itemId) => $emit('pin-remove', itemId)"
        />
      </draggable>
      <div v-else class="gl-text-secondary gl-font-sm gl-py-3" style="margin-left: 2.5rem">
        {{ $options.i18n.emptyHint }}
      </div>
    </gl-collapse>
    <hr class="gl-my-2" />
  </section>
</template>
