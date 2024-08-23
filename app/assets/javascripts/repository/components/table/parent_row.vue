<script>
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { joinPaths, buildURLwithRefType } from '~/lib/utils/url_utility';

export default {
  components: {
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['refType'],
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

      return splitArray.map((p) => encodeURIComponent(p)).join('/');
    },
    parentRoute() {
      const path = joinPaths('/-/tree', this.commitRef, this.parentPath);

      return buildURLwithRefType({ path, refType: this.refType });
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
    <td
      v-gl-tooltip.left.viewport
      :title="__('Go to parent directory')"
      colspan="3"
      class="tree-item-file-name"
      @click.self="clickRow"
    >
      <gl-loading-icon
        v-if="parentPath === loadingPath"
        size="sm"
        inline
        class="align-text-bottom gl-inline-block"
      />
      <router-link v-else :to="parentRoute" :aria-label="__('Go to parent')"> .. </router-link>
    </td>
  </tr>
</template>
