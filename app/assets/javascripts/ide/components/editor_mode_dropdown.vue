<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { viewerTypes } from '../constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    viewer: {
      type: String,
      required: true,
    },
    mergeRequestId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    modeDropdownItems() {
      return [
        {
          viewerType: this.$options.viewerTypes.mr,
          title: sprintf(__('Reviewing (merge request !%{mergeRequestId})'), {
            mergeRequestId: this.mergeRequestId,
          }),
          content: __('Compare changes with the merge request target branch'),
        },
        {
          viewerType: this.$options.viewerTypes.diff,
          title: __('Reviewing'),
          content: __('Compare changes with the last commit'),
        },
      ];
    },
  },
  methods: {
    changeMode(mode) {
      this.$emit('click', mode);
    },
  },
  viewerTypes,
};
</script>

<template>
  <gl-dropdown :text="__('Edit')" size="small">
    <gl-dropdown-item
      v-for="mode in modeDropdownItems"
      :key="mode.viewerType"
      is-check-item
      :is-checked="viewer === mode.viewerType"
      @click="changeMode(mode.viewerType)"
    >
      <strong class="dropdown-menu-inner-title"> {{ mode.title }} </strong>
      <span class="dropdown-menu-inner-content"> {{ mode.content }} </span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
