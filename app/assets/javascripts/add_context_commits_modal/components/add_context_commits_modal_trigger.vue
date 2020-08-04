<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  props: {
    commitsEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
    contextCommitsEmpty: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    buttonText() {
      return this.contextCommitsEmpty || this.commitsEmpty
        ? s__('AddContextCommits|Add previously merged commits')
        : s__('AddContextCommits|Add/remove');
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal');
    },
  },
};
</script>

<template>
  <gl-button
    :class="[
      {
        'ml-3': !contextCommitsEmpty,
        'mt-3': !commitsEmpty && contextCommitsEmpty,
      },
    ]"
    :variant="commitsEmpty ? 'info' : 'default'"
    @click="openModal"
  >
    {{ buttonText }}
  </gl-button>
</template>
