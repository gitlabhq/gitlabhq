<script>
  import { mapActions } from 'vuex';
  import icon from '../../../vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
    computed: {
      iconName() {
        return this.file.tempFile ? 'file-addition' : 'file-modified';
      },
      iconClass() {
        return `multi-file-${this.file.tempFile ? 'addition' : 'modified'} append-right-8`;
      },
    },
    methods: {
      ...mapActions([
        'discardFileChanges',
      ]),
    },
  };
</script>

<template>
  <div class="multi-file-commit-list-item">
    <icon
      :name="iconName"
      :size="16"
      :css-classes="iconClass"
    />
    <span class="multi-file-commit-list-path">
      {{ file.path }}
    </span>
    <button
      type="button"
      class="btn btn-blank multi-file-discard-btn"
      @click="discardFileChanges(file)"
    >
      Discard
    </button>
  </div>
</template>
