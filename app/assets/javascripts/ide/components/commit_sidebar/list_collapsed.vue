<script>
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import { sprintf, n__, __ } from '~/locale';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    files: {
      type: Array,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
  computed: {
    addedFilesLength() {
      return this.files.filter(f => f.tempFile).length;
    },
    modifiedFilesLength() {
      return this.files.filter(f => !f.tempFile).length;
    },
    addedFilesIconClass() {
      return this.addedFilesLength ? 'multi-file-addition' : '';
    },
    modifiedFilesClass() {
      return this.modifiedFilesLength ? 'multi-file-modified' : '';
    },
    additionsTooltip() {
      return sprintf(n__('1 %{type} addition', '%d %{type} additions', this.addedFilesLength), {
        type: this.title.toLowerCase(),
      });
    },
    modifiedTooltip() {
      return sprintf(
        n__('1 %{type} modification', '%d %{type} modifications', this.modifiedFilesLength),
        { type: this.title.toLowerCase() },
      );
    },
    titleTooltip() {
      return sprintf(__('%{title} changes'), { title: this.title });
    },
    additionIconName() {
      return this.title.toLowerCase() === 'staged' ? 'file-addition-solid' : 'file-addition';
    },
    modifiedIconName() {
      return this.title.toLowerCase() === 'staged' ? 'file-modified-solid' : 'file-modified';
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-list-collapsed text-center"
  >
    <div
      v-tooltip
      :title="titleTooltip"
      data-container="body"
      data-placement="left"
      class="append-bottom-15"
    >
      <icon
        v-once
        :name="iconName"
        :size="18"
      />
    </div>
    <div
      v-tooltip
      :title="additionsTooltip"
      data-container="body"
      data-placement="left"
      class="append-bottom-10"
    >
      <icon
        :name="additionIconName"
        :size="18"
        :css-classes="addedFilesIconClass"
      />
    </div>
    {{ addedFilesLength }}
    <div
      v-tooltip
      :title="modifiedTooltip"
      data-container="body"
      data-placement="left"
      class="prepend-top-10 append-bottom-10"
    >
      <icon
        :name="modifiedIconName"
        :size="18"
        :css-classes="modifiedFilesClass"
      />
    </div>
    {{ modifiedFilesLength }}
  </div>
</template>
