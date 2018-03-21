<script>
import Icon from '~/vue_shared/components/icon.vue';
import StageButton from './stage_button.vue';
import UnstageButton from './unstage_button.vue';
import router from '../../ide_router';

export default {
  components: {
    Icon,
    StageButton,
    UnstageButton,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    actionComponent: {
      type: String,
      required: true,
    },
  },
  computed: {
    iconName() {
      return this.file.tempFile ? 'file-addition' : 'file-modified';
    },
    iconClass() {
      return `multi-file-${
        this.file.tempFile ? 'addition' : 'modified'
      } append-right-8`;
    },
  },
  methods: {
    ...mapActions(['updateViewer']),
    openFileInEditor(file) {
      this.updateViewer('diff');

      router.push(`/project${file.url}`);
    },
  },
};
</script>

<template>
  <div class="multi-file-commit-list-item">
    <button
      type="button"
      class="multi-file-commit-list-path"
      @click="openFileInEditor(file)">
      <span class="multi-file-commit-list-file-path">
        <icon
          :name="iconName"
          :size="16"
          :css-classes="iconClass"
        />{{ file.path }}
      </span>
    </button>
    <component
      :is="actionComponent"
      :file="file"
    />
  </div>
</template>
