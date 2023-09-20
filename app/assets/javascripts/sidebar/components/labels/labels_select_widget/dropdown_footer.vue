<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
  },
  inject: ['allowLabelCreate', 'labelsManagePath'],
  props: {
    footerCreateLabelTitle: {
      type: String,
      required: true,
    },
    footerManageLabelTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    showManageLabelsItem() {
      return this.footerManageLabelTitle && this.labelsManagePath;
    },
  },
};
</script>

<template>
  <div data-testid="dropdown-footer">
    <gl-dropdown-item
      v-if="allowLabelCreate"
      data-testid="create-label-button"
      @click.capture.native.stop="$emit('toggleDropdownContentsCreateView')"
    >
      {{ footerCreateLabelTitle }}
    </gl-dropdown-item>
    <gl-dropdown-item
      v-if="showManageLabelsItem"
      data-testid="manage-labels-button"
      :href="labelsManagePath"
      @click.capture.native.stop
    >
      {{ footerManageLabelTitle }}
    </gl-dropdown-item>
  </div>
</template>
