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
    fileName: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-text-center gl-py-13 gl-bg-gray-50" data-type="lfs">
    <gl-sprintf :message="$options.i18n.lfsText">
      <template #link="{ content }">
        <gl-link :href="filePath" :download="fileName" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
