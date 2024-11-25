<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';

export default {
  name: 'PackagePath',
  components: {
    GlIcon,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    pathPieces() {
      return this.path.split('/');
    },
    root() {
      // we skip the first part of the path since is the 'base' group
      return this.pathPieces[1];
    },
    rootLink() {
      return joinPaths(this.pathPieces[0], this.root);
    },
    leaf() {
      return this.pathPieces[this.pathPieces.length - 1];
    },
    deeplyNested() {
      return this.pathPieces.length > 3;
    },
    hasGroup() {
      return this.root !== this.leaf;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <gl-icon data-testid="base-icon" name="project" class="gl-mx-3 gl-min-w-0" />

    <gl-link
      data-testid="root-link"
      class="gl-min-w-0 gl-text-subtle"
      :href="`/${rootLink}`"
      :disabled="disabled"
    >
      {{ root }}
    </gl-link>

    <template v-if="hasGroup">
      <gl-icon data-testid="root-chevron" name="chevron-right" class="gl-mx-2 gl-min-w-0" />

      <template v-if="deeplyNested">
        <span
          v-gl-tooltip="{ title: path }"
          data-testid="ellipsis-icon"
          class="gl-min-w-0 gl-rounded-base gl-px-2 gl-shadow-inner-1-gray-200"
        >
          <gl-icon name="ellipsis_h" />
        </span>
        <gl-icon data-testid="ellipsis-chevron" name="chevron-right" class="gl-mx-2 gl-min-w-0" />
      </template>

      <gl-link
        data-testid="leaf-link"
        class="gl-min-w-0 gl-text-subtle"
        :href="`/${path}`"
        :disabled="disabled"
      >
        {{ leaf }}
      </gl-link>
    </template>
  </div>
</template>
