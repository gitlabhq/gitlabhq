<script>
import Icon from '../../../vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    currentId: {
      type: String,
      required: true,
    },
    currentProjectId: {
      type: String,
      required: true,
    },
  },
  computed: {
    isActive() {
      return (
        this.item.iid === parseInt(this.currentId, 10) &&
        this.currentProjectId === this.item.projectPathWithNamespace
      );
    },
    pathWithID() {
      return `${this.item.projectPathWithNamespace}!${this.item.iid}`;
    },
  },
  methods: {
    clickItem() {
      this.$emit('click', this.item);
    },
  },
};
</script>

<template>
  <button
    type="button"
    class="d-flex align-items-center"
    @click.prevent.stop="clickItem"
  >
    <span
      class="d-flex append-right-default"
      style="min-width: 18px"
    >
      <icon
        v-if="isActive"
        name="mobile-issue-close"
        :size="18"
      />
    </span>
    <span>
      <strong>
        {{ item.title }}
      </strong>
      <span class="d-block mt-1">
        {{ pathWithID }}
      </span>
    </span>
  </button>
</template>
