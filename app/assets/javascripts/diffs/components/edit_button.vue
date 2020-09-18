<script>
import { uniqueId } from 'lodash';
import {
  GlTooltipDirective,
  GlIcon,
  GlDeprecatedDropdown as GlDropdown,
  GlDeprecatedDropdownItem as GlDropdownItem,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
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
    ideEditPath: {
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
  data() {
    return { tooltipId: uniqueId('edit_button_tooltip_') };
  },
  computed: {
    tooltipTitle() {
      if (this.isDisabled) {
        return __("Can't edit as source branch was deleted");
      }

      return __('Edit file in...');
    },
    isDisabled() {
      return !this.editPath;
    },
  },
  methods: {
    handleShow(evt) {
      // We must hide the tooltip because it is redundant and doesn't close itself
      // when dropdown opens because we are still "focused".
      this.$root.$emit('bv::hide::tooltip', this.tooltipId);

      if (this.canCurrentUserFork && !this.canModifyBlob) {
        evt.preventDefault();
        this.$emit('showForkMessage');
      } else {
        this.$emit('open');
      }
    },
    handleHide() {
      this.$emit('close');
    },
  },
};
</script>

<template>
  <div v-gl-tooltip.top="{ title: tooltipTitle, id: tooltipId }" class="gl-display-flex">
    <gl-dropdown
      toggle-class="rounded-0"
      :disabled="isDisabled"
      :class="{ 'cursor-not-allowed': isDisabled }"
      right
      data-testid="edit_file"
      @show="handleShow"
      @hide="handleHide"
    >
      <template #button-content>
        <span class="gl-dropdown-toggle-text"><gl-icon name="pencil"/></span>
        <gl-icon class="gl-dropdown-caret" name="chevron-down" aria-hidden="true" />
      </template>
      <gl-dropdown-item v-if="editPath" :href="editPath">{{
        __('Edit in single-file editor')
      }}</gl-dropdown-item>
      <gl-dropdown-item v-if="ideEditPath" :href="ideEditPath">{{
        __('Edit in Web IDE')
      }}</gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
