<script>
import { GlSprintf } from '@gitlab/ui';
import UserDate from '~/vue_shared/components/user_date.vue';

export default {
  name: 'CreatedAt',
  components: { GlSprintf, UserDate },
  props: {
    date: {
      type: String,
      required: false,
      default: null,
    },
    createdBy: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    showCreatedBy() {
      return this.createdBy?.name && this.createdBy?.webUrl;
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf v-if="showCreatedBy" :message="s__('Members|%{time} by %{user}')">
      <template #time>
        <user-date :date="date" />
      </template>
      <template #user>
        <a :href="createdBy.webUrl">{{ createdBy.name }}</a>
      </template>
    </gl-sprintf>
    <user-date v-else :date="date" />
  </span>
</template>
