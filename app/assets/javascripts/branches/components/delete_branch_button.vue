<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  name: 'DeleteBranchButton',
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    branchName: {
      type: String,
      required: false,
      default: '',
    },
    defaultBranchName: {
      type: String,
      required: false,
      default: '',
    },
    deletePath: {
      type: String,
      required: false,
      default: '',
    },
    tooltip: {
      type: String,
      required: false,
      default: s__('Branches|Delete branch'),
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProtectedBranch: {
      type: Boolean,
      required: false,
      default: false,
    },
    merged: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      if (this.isProtectedBranch && this.disabled) {
        return s__('Branches|Only a project maintainer or owner can delete a protected branch');
      } else if (this.isProtectedBranch) {
        return s__('Branches|Delete protected branch');
      }
      return this.tooltip;
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', {
        branchName: this.branchName,
        defaultBranchName: this.defaultBranchName,
        deletePath: this.deletePath,
        isProtectedBranch: this.isProtectedBranch,
        merged: this.merged,
      });
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    icon="remove"
    class="js-delete-branch-button"
    data-qa-selector="delete_branch_button"
    :disabled="disabled"
    variant="default"
    :title="title"
    :aria-label="title"
    @click="openModal"
  />
</template>
