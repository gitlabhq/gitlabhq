<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    commitRef: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    loadingPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    parentPath() {
      const splitArray = this.path.split('/');
      splitArray.pop();

      return splitArray.join('/');
    },
    parentRoute() {
      return { path: `/tree/${this.commitRef}/${this.parentPath}` };
    },
  },
  methods: {
    clickRow() {
      this.$router.push(this.parentRoute);
    },
  },
};
</script>

<template>
  <tr class="tree-item">
    <td colspan="3" class="tree-item-file-name" @click.self="clickRow">
      <gl-loading-icon
        v-if="parentPath === loadingPath"
        size="sm"
        inline
        class="d-inline-block align-text-bottom"
      />
      <router-link v-else :to="parentRoute" :aria-label="__('Go to parent')">
        ..
      </router-link>
    </td>
  </tr>
</template>
