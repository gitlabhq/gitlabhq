<script>
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showButtons() {
      return (
        this.file.rawPath || this.file.blamePath || this.file.commitsPath || this.file.permalink
      );
    },
    rawDownloadButtonLabel() {
      return this.file.binary ? __('Download') : __('Raw');
    },
  },
};
</script>

<template>
  <div
    v-if="showButtons"
    class="float-right ide-btn-group"
  >
    <a
      v-tooltip
      v-if="!file.binary"
      :href="file.blamePath"
      :title="__('Blame')"
      class="btn btn-sm btn-transparent blame"
    >
      <icon
        name="blame"
        :size="16"
      />
    </a>
    <a
      v-tooltip
      :href="file.commitsPath"
      :title="__('History')"
      class="btn btn-sm btn-transparent history"
    >
      <icon
        name="history"
        :size="16"
      />
    </a>
    <a
      v-tooltip
      :href="file.permalink"
      :title="__('Permalink')"
      class="btn btn-sm btn-transparent permalink"
    >
      <icon
        name="link"
        :size="16"
      />
    </a>
    <a
      v-tooltip
      :href="file.rawPath"
      target="_blank"
      class="btn btn-sm btn-transparent prepend-left-10 raw"
      rel="noopener noreferrer"
      :title="rawDownloadButtonLabel">
      <icon
        name="download"
        :size="16"
      />
    </a>
  </div>
</template>
