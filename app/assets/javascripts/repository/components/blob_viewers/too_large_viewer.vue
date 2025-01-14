<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: { GlSprintf, GlLink },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    header: s__('BlobViewer|The file could not be displayed because it is too large.'),
    collapsedDescription: s__(
      'BlobViewer|You can either %{rawLinkStart}view the raw file%{rawLinkEnd} or %{downloadLinkStart}download it%{downloadLinkEnd}.',
    ),
    tooLargeDescription: s__('BlobViewer|You can %{linkStart}download it%{linkEnd}.'),
  },
  computed: {
    blobViewer() {
      return this.blob.richViewer || this.blob.simpleViewer;
    },
    isCollapsed() {
      return this.blobViewer?.renderError === 'collapsed';
    },
    isTooLarge() {
      return this.blobViewer?.tooLarge;
    },
    filePath() {
      return this.blob.externalStorageUrl || this.blob.rawPath;
    },
    fileName() {
      return this.blob.name;
    },
  },
};
</script>

<template>
  <div class="gl-p-6 gl-text-center">
    {{ $options.i18n.header }}

    <gl-sprintf v-if="isCollapsed" :message="$options.i18n.collapsedDescription">
      <template #rawLink="{ content }">
        <gl-link :href="filePath" rel="nofollow" target="_blank">{{ content }}</gl-link>
      </template>
      <template #downloadLink="{ content }">
        <gl-link :href="filePath" rel="nofollow" target="_blank" :download="fileName">{{
          content
        }}</gl-link>
      </template>
    </gl-sprintf>

    <gl-sprintf v-else-if="isTooLarge" :message="$options.i18n.tooLargeDescription">
      <template #link="{ content }">
        <gl-link :href="filePath" rel="nofollow" :download="fileName" target="_blank">{{
          content
        }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
