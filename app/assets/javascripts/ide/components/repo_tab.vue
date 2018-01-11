<script>
  import { mapActions } from 'vuex';
  import fileStatusIcon from './repo_file_status_icon.vue';
  import fileIcon from '../../vue_shared/components/file_icon.vue';

  export default {
    components: {
      fileStatusIcon,
      fileIcon,
    },
    props: {
      tab: {
        type: Object,
        required: true,
      },
    },
    computed: {
      closeLabel() {
        if (this.tab.changed || this.tab.tempFile) {
          return `${this.tab.name} changed`;
        }
        return `Close ${this.tab.name}`;
      },
      changedClass() {
        const tabChangedObj = {
          'fa-times close-icon': !this.tab.changed && !this.tab.tempFile,
          'fa-circle unsaved-icon': this.tab.changed || this.tab.tempFile,
        };
        return tabChangedObj;
      },
    },

    methods: {
      ...mapActions([
        'closeFile',
      ]),
      clickFile(tab) {
        this.$router.push(`/project${tab.url}`);
      },
    },
  };
</script>

<template>
  <li @click="clickFile(tab)">
    <button
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile({ file: tab })"
      :aria-label="closeLabel"
      :class="{
        'modified': tab.changed,
      }"
      :disabled="tab.changed"
    >
      <i
        class="fa"
        :class="changedClass"
        aria-hidden="true"
      >
      </i>
    </button>

    <div
      class="multi-file-tab"
      :class="{active : tab.active }"
      :title="tab.url"
    >
      <file-icon
        :file-name="tab.name"
        :size="16"
      />
      {{ tab.name }}
      <file-status-icon
        :file="tab"
      />
    </div>
  </li>
</template>
