<script>
import { GlDropdownItem } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalAttributes() {
      return {
        'data-path': this.path,
        'data-method': 'put',
        'data-modal-attributes': JSON.stringify({
          title: sprintf(s__('AdminUsers|Unlock user %{username}?'), { username: this.username }),
          message: __('Are you sure?'),
          okVariant: 'confirm',
          okTitle: s__('AdminUsers|Unlock'),
        }),
      };
    },
  },
};
</script>

<template>
  <div class="js-confirm-modal-button" v-bind="{ ...modalAttributes }">
    <gl-dropdown-item>
      <slot></slot>
    </gl-dropdown-item>
  </div>
</template>
