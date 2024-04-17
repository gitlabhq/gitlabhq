<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { BLOB_RENDER_ERRORS } from './constants';

export default {
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    viewerError: {
      type: String,
      required: true,
    },
    blob: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    notStoredExternally() {
      return this.viewerError !== BLOB_RENDER_ERRORS.REASONS.EXTERNAL.id;
    },
    renderErrorReason() {
      const defaultReasonPath = Object.keys(BLOB_RENDER_ERRORS.REASONS).find(
        (reason) => BLOB_RENDER_ERRORS.REASONS[reason].id === this.viewerError,
      );
      const defaultReason = BLOB_RENDER_ERRORS.REASONS[defaultReasonPath].text;
      return this.notStoredExternally
        ? defaultReason
        : defaultReason[this.blob.externalStorage || 'default'];
    },
    renderErrorOptions() {
      const load = {
        ...BLOB_RENDER_ERRORS.OPTIONS.LOAD,
        condition: this.shouldShowLoadBtn,
      };
      const showSource = {
        ...BLOB_RENDER_ERRORS.OPTIONS.SHOW_SOURCE,
        condition: this.shouldShowSourceBtn,
      };
      const download = {
        ...BLOB_RENDER_ERRORS.OPTIONS.DOWNLOAD,
        href: this.blob.rawPath,
      };
      return [load, showSource, download];
    },
    shouldShowLoadBtn() {
      return this.viewerError === BLOB_RENDER_ERRORS.REASONS.COLLAPSED.id;
    },
    shouldShowSourceBtn() {
      return this.blob.richViewer && this.blob.renderedAsText && this.notStoredExternally;
    },
  },
  errorMessage: __(
    'Content could not be displayed: %{reason}. Options to address this: %{options}.',
  ),
};
</script>
<template>
  <div class="file-content code">
    <div class="text-center py-4">
      <gl-sprintf :message="$options.errorMessage">
        <template #reason>{{ renderErrorReason }}</template>
        <template #options>
          <template v-for="option in renderErrorOptions">
            <span v-if="option.condition" :key="option.text">
              <gl-link
                :href="option.href"
                :target="option.target"
                :data-test-id="`option-${option.id}`"
                @click="option.event && $emit(option.event)"
                >{{ option.text }}</gl-link
              >
              {{ option.conjunction }}
            </span>
          </template>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
