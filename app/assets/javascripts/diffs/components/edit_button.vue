<script>
import { GlTooltipDirective, GlDeprecatedButton } from '@gitlab/ui';
import { __ } from '~/locale';
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
      required: false,
      default: '',
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
  computed: {
    tooltipTitle() {
      if (this.isDisabled) {
        return __("Can't edit as source branch was deleted");
      }

      return __('Edit file');
    },
    isDisabled() {
      return !this.editPath;
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
  <span v-gl-tooltip.top :title="tooltipTitle">
    <gl-deprecated-button
      :href="editPath"
      :disabled="isDisabled"
      :class="{ 'cursor-not-allowed': isDisabled }"
      class="rounded-0 js-edit-blob"
      @click.native="handleEditClick"
    >
      <icon name="pencil" />
    </gl-deprecated-button>
  </span>
</template>
