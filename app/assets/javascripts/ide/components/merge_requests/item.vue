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
    class="btn-link d-flex align-items-center"
    @click="clickItem"
  >
    <span class="d-flex append-right-default ide-merge-request-current-icon">
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
      <span class="ide-merge-request-project-path d-block mt-1">
        {{ pathWithID }}
      </span>
    </span>
  </button>
</template>
