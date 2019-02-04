<script>
import { GlLink } from '@gitlab/ui';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    TimeagoTooltip,
    GlLink,
  },
  mixins: [timeagoMixin],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isExpired() {
      return this.artifact.expired;
    },
    // Only when the key is `false` we can render this block
    willExpire() {
      return this.artifact.expired === false;
    },
  },
};
</script>
<template>
  <div class="block">
    <div class="title font-weight-bold">{{ s__('Job|Job artifacts') }}</div>

    <p
      v-if="isExpired || willExpire"
      :class="{
        'js-artifacts-removed': isExpired,
        'js-artifacts-will-be-removed': willExpire,
      }"
      class="build-detail-row"
    >
      <span v-if="isExpired">{{ s__('Job|The artifacts were removed') }}</span>
      <span v-if="willExpire">{{ s__('Job|The artifacts will be removed') }}</span>
      <timeago-tooltip v-if="artifact.expire_at" :time="artifact.expire_at" />
    </p>

    <div class="btn-group d-flex prepend-top-10" role="group">
      <gl-link
        v-if="artifact.keep_path"
        :href="artifact.keep_path"
        class="js-keep-artifacts btn btn-sm btn-default"
        data-method="post"
        >{{ s__('Job|Keep') }}</gl-link
      >

      <gl-link
        v-if="artifact.download_path"
        :href="artifact.download_path"
        class="js-download-artifacts btn btn-sm btn-default"
        download
        rel="nofollow"
        >{{ s__('Job|Download') }}</gl-link
      >

      <gl-link
        v-if="artifact.browse_path"
        :href="artifact.browse_path"
        class="js-browse-artifacts btn btn-sm btn-default"
        >{{ s__('Job|Browse') }}</gl-link
      >
    </div>
  </div>
</template>
