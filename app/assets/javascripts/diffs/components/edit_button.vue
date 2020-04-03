<script>
import { GlTooltipDirective, GlDeprecatedButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlDeprecatedButton,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    editPath: {
      type: String,
      required: true,
    },
    canCurrentUserFork: {
      type: Boolean,
      required: true,
    },
    canModifyBlob: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    handleEditClick(evt) {
      if (this.canCurrentUserFork && !this.canModifyBlob) {
        evt.preventDefault();
        this.$emit('showForkMessage');
      }
    },
  },
};
</script>

<template>
  <gl-deprecated-button
    v-gl-tooltip.top
    :href="editPath"
    :title="__('Edit file')"
    class="js-edit-blob"
    @click.native="handleEditClick"
  >
    <icon name="pencil" />
  </gl-deprecated-button>
</template>
