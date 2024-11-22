<script>
export default {
  name: 'DependencyRow',
  props: {
    dependencyLink: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showVersion() {
      return Boolean(this.dependencyLink.dependency?.versionPattern);
    },
    showTargetFramework() {
      return Boolean(this.dependencyLink.metadata?.targetFramework);
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row">
    <div class="table-section section-50">
      <strong class="gl-text-default">{{ dependencyLink.dependency.name }}</strong>
      <span v-if="showTargetFramework" data-testid="target-framework">
        ({{ dependencyLink.metadata.targetFramework }})
      </span>
    </div>

    <div
      v-if="showVersion"
      class="table-section section-50 gl-flex md:gl-justify-end"
      data-testid="version-pattern"
    >
      <span class="gl-text-default">{{ dependencyLink.dependency.versionPattern }}</span>
    </div>
  </div>
</template>
