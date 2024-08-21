<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

import {
  I18N_CREATED_AT_LABEL,
  I18N_CREATED_BY_LABEL,
  I18N_CREATED_BY_AT_LABEL,
} from '../constants';

export default {
  components: {
    GlSprintf,
    GlLink,
    TimeAgo,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    createdAt() {
      return this.runner?.createdAt;
    },
    createdBy() {
      return this.runner?.createdBy;
    },
    createdById() {
      if (this.createdBy?.id) {
        return getIdFromGraphQLId(this.createdBy.id);
      }
      return null;
    },
    message() {
      if (this.createdBy && this.createdAt) {
        return I18N_CREATED_BY_AT_LABEL;
      }
      if (this.createdBy) {
        return I18N_CREATED_BY_LABEL;
      }
      if (this.createdAt) {
        return I18N_CREATED_AT_LABEL;
      }

      return null;
    },
  },
};
</script>
<template>
  <span v-if="message">
    <gl-sprintf :message="message">
      <template #timeAgo>
        <time-ago v-if="createdAt" :time="createdAt" />
      </template>
      <template #user>
        <gl-link
          class="js-user-link gl-font-bold gl-text-inherit"
          :href="createdBy.webUrl"
          :data-user-id="createdById"
          :data-username="createdBy.username"
          :data-name="createdBy.name"
          :data-avatar-url="createdBy.avatarUrl"
          >{{ createdBy.name }}</gl-link
        >
      </template>
    </gl-sprintf>
  </span>
</template>
