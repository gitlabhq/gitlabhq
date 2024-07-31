<script>
/**
 * An instance in deploy board is represented by a square in this mockup:
 * https://gitlab.com/gitlab-org/gitlab-foss/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png
 *
 * Each instance has a state and a tooltip.
 * The state needs to be represented in different colors,
 * see more information about this in
 * https://gitlab.com/gitlab-org/gitlab/uploads/f1f00df6293d30f241dbeaa876a1e939/Screen_Shot_2019-11-26_at_3.35.43_PM.png
 *
 * An instance can represent a normal deploy or a canary deploy. In the latter we need to provide
 * this information in the tooltip and the colors.
 * Mockup is https://gitlab.com/gitlab-org/gitlab/issues/35570
 */
import { GlLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    /**
     * Represents the status of the pod. Each state is represented with a different
     * color.
     * It should be one of the following:
     * succeeded || running || failed || pending || unknown
     */
    status: {
      type: String,
      required: true,
      default: 'succeeded',
    },

    tooltipText: {
      type: String,
      required: false,
      default: '',
    },

    stable: {
      type: Boolean,
      required: false,
      default: true,
    },

    podName: {
      type: String,
      required: false,
      default: '',
    },
  },

  computed: {
    isLink() {
      return this.podName !== '';
    },

    cssClass() {
      return {
        [`deployment-instance-${this.status}`]: true,
        'deployment-instance-canary': !this.stable,
        link: this.isLink,
      };
    },
  },
};
</script>
<template>
  <gl-link
    v-gl-tooltip
    :class="cssClass"
    :title="tooltipText"
    class="deployment-instance justify-content-center gl-flex gl-items-center"
  />
</template>
