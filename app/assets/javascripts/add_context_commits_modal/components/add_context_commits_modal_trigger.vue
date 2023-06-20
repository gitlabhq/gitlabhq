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
        'gl-ml-5': !contextCommitsEmpty,
        'gl-mt-1': !commitsEmpty && contextCommitsEmpty,
      },
    ]"
    :variant="commitsEmpty ? 'confirm' : 'default'"
    @click="openModal"
  >
    {{ buttonText }}
  </gl-button>
</template>
