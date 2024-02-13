<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    newGroup: __('New group'),
  },
  components: {
    GlButton,
  },
  inject: ['canCreateGroup', 'newGroupPath'],
  props: {
    category: {
      type: String,
      required: false,
      default: 'primary',
    },
  },
  computed: {
    showButton() {
      return this.canCreateGroup && this.newGroupPath;
    },
  },
};
</script>

<template>
  <gl-button v-if="showButton" :href="newGroupPath" :category="category" variant="confirm">{{
    $options.i18n.newGroup
  }}</gl-button>
</template>
