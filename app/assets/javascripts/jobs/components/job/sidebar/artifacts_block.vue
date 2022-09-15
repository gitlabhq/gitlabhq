<script>
import { GlButton, GlButtonGroup, GlIcon, GlLink } from '@gitlab/ui';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlIcon,
    GlLink,
    TimeagoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
    helpUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    isExpired() {
      return this.artifact?.expired && !this.isLocked;
    },
    isLocked() {
      return this.artifact?.locked;
    },
    // Only when the key is `false` we can render this block
    willExpire() {
      return this.artifact?.expired === false && !this.isLocked;
    },
  },
};
</script>
<template>
  <div>
    <div class="title gl-font-weight-bold">{{ s__('Job|Job artifacts') }}</div>
    <p
      v-if="isExpired || willExpire"
      class="build-detail-row"
      data-testid="artifacts-remove-timeline"
    >
      <span v-if="isExpired">{{ s__('Job|The artifacts were removed') }}</span>
      <span v-if="willExpire">{{ s__('Job|The artifacts will be removed') }}</span>
      <timeago-tooltip v-if="artifact.expire_at" :time="artifact.expire_at" />
      <gl-link
        :href="helpUrl"
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-testid="artifact-expired-help-link"
      >
        <gl-icon name="question" />
      </gl-link>
    </p>
    <p v-else-if="isLocked" class="build-detail-row">
      <span data-testid="job-locked-message">{{
        s__(
          'Job|These artifacts are the latest. They will not be deleted (even if expired) until newer artifacts are available.',
        )
      }}</span>
    </p>
    <gl-button-group class="gl-display-flex gl-mt-3">
      <gl-button
        v-if="artifact.keep_path"
        :href="artifact.keep_path"
        data-method="post"
        data-testid="keep-artifacts"
        >{{ s__('Job|Keep') }}</gl-button
      >
      <gl-button
        v-if="artifact.download_path"
        :href="artifact.download_path"
        rel="nofollow"
        data-testid="download-artifacts"
        download
        >{{ s__('Job|Download') }}</gl-button
      >
      <gl-button
        v-if="artifact.browse_path"
        :href="artifact.browse_path"
        data-testid="browse-artifacts"
        data-qa-selector="browse_artifacts_button"
        >{{ s__('Job|Browse') }}</gl-button
      >
    </gl-button-group>
  </div>
</template>
