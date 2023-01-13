<script>
import { GlButtonGroup, GlButton, GlBadge, GlFriendlyWrap } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { I18N_EXPIRED, I18N_DOWNLOAD, I18N_DELETE } from '../constants';

export default {
  name: 'ArtifactRow',
  components: {
    GlButtonGroup,
    GlButton,
    GlBadge,
    GlFriendlyWrap,
  },
  inject: ['canDestroyArtifacts'],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
    isLastRow: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isExpired() {
      if (!this.artifact.expireAt) {
        return false;
      }
      return Date.now() > new Date(this.artifact.expireAt).getTime();
    },
    artifactSize() {
      return numberToHumanSize(this.artifact.size);
    },
  },
  i18n: {
    expired: I18N_EXPIRED,
    download: I18N_DOWNLOAD,
    delete: I18N_DELETE,
  },
};
</script>
<template>
  <div
    class="gl-py-4"
    :class="{ 'gl-border-b-solid gl-border-b-1 gl-border-gray-100': !isLastRow }"
  >
    <div class="gl-display-inline-flex gl-align-items-center gl-w-full">
      <span
        class="gl-w-half gl-pl-8 gl-display-flex gl-align-items-center"
        data-testid="job-artifact-row-name"
      >
        <gl-friendly-wrap :text="artifact.name" />
        <gl-badge size="sm" variant="neutral" class="gl-ml-2">
          {{ artifact.fileType.toLowerCase() }}
        </gl-badge>
        <gl-badge v-if="isExpired" size="sm" variant="warning" icon="expire" class="gl-ml-2">
          {{ $options.i18n.expired }}
        </gl-badge>
      </span>

      <span class="gl-w-quarter gl-text-right gl-pr-5" data-testid="job-artifact-row-size">
        {{ artifactSize }}
      </span>

      <span class="gl-w-quarter gl-text-right gl-pr-5">
        <gl-button-group>
          <gl-button
            category="tertiary"
            icon="download"
            :title="$options.i18n.download"
            :aria-label="$options.i18n.download"
            :href="artifact.downloadPath"
            data-testid="job-artifact-row-download-button"
          />
          <gl-button
            v-if="canDestroyArtifacts"
            category="tertiary"
            icon="remove"
            :title="$options.i18n.delete"
            :aria-label="$options.i18n.delete"
            data-testid="job-artifact-row-delete-button"
            @click="$emit('delete')"
          />
        </gl-button-group>
      </span>
    </div>
  </div>
</template>
