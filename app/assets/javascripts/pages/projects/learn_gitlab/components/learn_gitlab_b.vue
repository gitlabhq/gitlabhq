<script>
import { GlLink } from '@gitlab/ui';
import { ACTION_TEXT } from '../constants';

export default {
  components: { GlLink },
  i18n: {
    ACTION_TEXT,
  },
  props: {
    actions: {
      required: true,
      type: Object,
    },
  },
};
</script>
<template>
  <ul>
    <li v-for="(value, action) in actions" :key="action">
      <span v-if="value.completed">{{ $options.i18n.ACTION_TEXT[action] }}</span>
      <span v-else>
        <gl-link :href="value.url">{{ $options.i18n.ACTION_TEXT[action] }}</gl-link>
      </span>
    </li>
  </ul>
</template>
