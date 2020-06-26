<script>
import { isEmpty } from 'lodash';
import { GlLink } from '@gitlab/ui';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    TimeagoTooltip,
    GlLink,
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
  <div class="gl-mt-3 js-build-erased">
    <div class="erased alert alert-warning">
      <template v-if="isErasedByUser">
        {{ s__('Job|Job has been erased by') }}
        <gl-link :href="user.web_url"> {{ user.username }} </gl-link>
      </template>
      <template v-else>
        {{ s__('Job|Job has been erased') }}
      </template>

      <timeago-tooltip :time="erasedAt" />
    </div>
  </div>
</template>
