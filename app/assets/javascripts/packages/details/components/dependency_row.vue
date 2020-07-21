<script>
export default {
  name: 'DependencyRow',
  props: {
    dependency: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showVersion() {
      return Boolean(this.dependency.version_pattern);
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row">
    <div class="table-section section-50">
      <strong class="gl-text-black-normal">{{ dependency.name }}</strong>
      <span v-if="dependency.target_framework" data-testid="target-framework"
        >({{ dependency.target_framework }})</span
      >
    </div>

    <div
      v-if="showVersion"
      class="table-section section-50 gl-display-flex justify-content-md-end"
      data-testid="version-pattern"
    >
      <span class="gl-text-black-normal">{{ dependency.version_pattern }}</span>
    </div>
  </div>
</template>
