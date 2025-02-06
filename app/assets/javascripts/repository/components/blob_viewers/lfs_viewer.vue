<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    lfsText: __(
      'This content could not be displayed because it is stored in LFS. You can %{linkStart}download it%{linkEnd} instead.',
    ),
  },
  components: {
    GlLink,
    GlSprintf,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      fileName: this.blob.name,
      filePath: this.blob.externalStorageUrl || this.blob.rawPath,
    };
  },
};
</script>

<template>
  <div class="gl-bg-strong gl-py-13 gl-text-center" data-type="lfs">
    <gl-sprintf :message="$options.i18n.lfsText">
      <template #link="{ content }">
        <gl-link :href="filePath" :download="fileName" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
