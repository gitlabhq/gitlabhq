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
    description: s__(
      'BlobViewer|You can either %{rawLinkStart}view the raw file%{rawLinkEnd} or %{downloadLinkStart}download it%{downloadLinkEnd}.',
    ),
  },
  computed: {
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

    <gl-sprintf :message="$options.i18n.description">
      <template #rawLink="{ content }">
        <gl-link :href="filePath" rel="nofollow" target="_blank">{{ content }}</gl-link>
      </template>
      <template #downloadLink="{ content }">
        <gl-link :href="filePath" rel="nofollow" target="_blank" :download="fileName">{{
          content
        }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
