<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  props: {
    displayText: {
      type: String,
      required: false,
      default: s__('ImportAProjectModal|Import from a project'),
    },
    classes: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openProjectMembersModal');
    },
  },
};
</script>

<template>
  <gl-button :class="classes" @click="openModal">
    {{ displayText }}
  </gl-button>
</template>
