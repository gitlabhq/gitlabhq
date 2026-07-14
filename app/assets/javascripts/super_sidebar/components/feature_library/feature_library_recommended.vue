<script>
import FeatureLibraryItem from './feature_library_item.vue';

export default {
  name: 'FeatureLibraryRecommended',
  components: { FeatureLibraryItem },
  props: {
    items: {
      type: Array,
      required: true,
    },
    pinnedIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['pin-toggle'],
  methods: {
    isPinned(itemId) {
      return this.pinnedIds.includes(itemId);
    },
    onPinToggle(itemId, nextState, title) {
      this.$emit('pin-toggle', itemId, nextState, title);
    },
  },
};
</script>

<template>
  <section class="gl-mb-5 gl-rounded-xl gl-bg-strong gl-p-4">
    <h3
      data-testid="feature-library-recommended-heading"
      class="gl-mb-3 gl-mt-0 gl-pl-2 gl-text-base gl-font-bold"
    >
      {{ s__('FeatureLibrary|Recommended') }}
    </h3>
    <ul
      data-testid="feature-library-recommended-grid"
      class="gl-mb-0 gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
    >
      <feature-library-item
        v-for="item in items"
        :key="item.id"
        :item="item"
        :pinned="isPinned(item.id)"
        solid-background
        @pin-toggle="onPinToggle"
      />
    </ul>
  </section>
</template>
