<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    TimeagoTooltip,
  },
  props: {
    user: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    erasedAt: {
      type: String,
      required: true,
    },
  },
  computed: {
    isErasedByUser() {
      return !isEmpty(this.user);
    },
  },
};
</script>
<template>
  <div class="gl-mt-3">
    <gl-alert variant="warning" :dismissible="false">
      <template v-if="isErasedByUser">
        <gl-sprintf :message="s__('Job|Job has been erased by %{userLink}')">
          <template #userLink>
            <gl-link :href="user.web_url" target="_blank">{{ user.username }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <template v-else>
        {{ s__('Job|Job has been erased') }}
      </template>

      <timeago-tooltip :time="erasedAt" />
    </gl-alert>
  </div>
</template>
