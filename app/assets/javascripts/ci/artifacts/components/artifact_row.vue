<script>
import {
  GlButtonGroup,
  GlButton,
  GlBadge,
  GlFriendlyWrap,
  GlFormCheckbox,
  GlTooltipDirective,
} from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import {
  I18N_EXPIRED,
  I18N_DOWNLOAD,
  I18N_DELETE,
  I18N_BULK_DELETE_MAX_SELECTED,
} from '../constants';

export default {
  name: 'ArtifactRow',
  components: {
    GlButtonGroup,
    GlButton,
    GlBadge,
    GlFriendlyWrap,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canDestroyArtifacts'],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
    isSelected: {
      type: Boolean,
      required: true,
    },
    isLastRow: {
      type: Boolean,
      required: true,
    },
    isSelectedArtifactsLimitReached: {
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
    isCheckboxDisabled() {
      return this.isSelectedArtifactsLimitReached && !this.isSelected;
    },
    checkboxTooltip() {
      return this.isCheckboxDisabled ? I18N_BULK_DELETE_MAX_SELECTED : '';
    },
    artifactSize() {
      return numberToHumanSize(this.artifact.size);
    },
    canBulkDestroyArtifacts() {
      return this.canDestroyArtifacts;
    },
  },
  methods: {
    handleInput(checked) {
      if (checked === this.isSelected) return;

      this.$emit('selectArtifact', this.artifact, checked);
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
  <div class="gl-py-4" :class="{ 'gl-border-b-1 gl-border-default gl-border-b-solid': !isLastRow }">
    <div class="gl-inline-flex gl-w-full gl-items-center">
      <span v-if="canBulkDestroyArtifacts" class="gl-pl-5">
        <gl-form-checkbox
          v-gl-tooltip.right
          :title="checkboxTooltip"
          :checked="isSelected"
          :disabled="isCheckboxDisabled"
          @input="handleInput"
        />
      </span>
      <span class="gl-flex gl-w-1/2 gl-items-center gl-pl-8" data-testid="job-artifact-row-name">
        <gl-friendly-wrap :text="artifact.name" />
        <gl-badge variant="neutral" class="gl-ml-2">
          {{ artifact.fileType.toLowerCase() }}
        </gl-badge>
        <gl-badge v-if="isExpired" variant="warning" icon="expire" class="gl-ml-2">
          {{ $options.i18n.expired }}
        </gl-badge>
      </span>

      <span class="gl-w-1/4 gl-pr-5 gl-text-right" data-testid="job-artifact-row-size">
        {{ artifactSize }}
      </span>

      <span class="gl-w-1/4 gl-pr-5 gl-text-right">
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
