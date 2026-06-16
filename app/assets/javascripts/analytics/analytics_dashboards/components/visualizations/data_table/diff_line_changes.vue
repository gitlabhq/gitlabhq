<script>
export default {
  name: 'DiffLineChanges',
  props: {
    additions: {
      type: Number,
      required: false,
      default: 0,
    },
    deletions: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    formattedAdditions() {
      return `+${this.additions}`;
    },
    formattedDeletions() {
      return `-${this.deletions}`;
    },
  },
};
</script>
<template>
  <div>
    <span class="gl-font-bold gl-text-success">{{ formattedAdditions }}</span>
    <span class="gl-font-bold gl-text-red-500">{{ formattedDeletions }}</span>
  </div>
</template>
