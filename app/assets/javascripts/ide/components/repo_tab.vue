<script>
  import { mapActions } from 'vuex';
  import fileIcon from '../../vue_shared/components/file_icon.vue';

  export default {
    components: {
      fileIcon,
    },
    props: {
      tab: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        tabMouseOver: false,
      };
    },
    computed: {
      closeLabel() {
        if (this.tab.changed || this.tab.tempFile) {
          return `${this.tab.name} changed`;
        }
        return `Close ${this.tab.name}`;
      },
      showChangedIcon() {
        return this.tab.changed ? !this.tabMouseOver : false;
      },
    },

    methods: {
      ...mapActions([
        'closeFile',
      ]),
      clickFile(tab) {
        this.$router.push(`/project${tab.url}`);
      },
      mouseOverTab() {
        if (this.tab.changed) {
          this.tabMouseOver = true;
        }
      },
      mouseOutTab() {
        if (this.tab.changed) {
          this.tabMouseOver = false;
        }
      },
    },
  };
</script>

<template>
  <li
    @click="clickFile(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <button
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile(tab)"
      :aria-label="closeLabel"
      :class="{
        'modified': tab.changed,
      }"
    >
      <i
        v-if="!showChangedIcon"
        class="fa fa-times close-icon"
        aria-hidden="true"
      >
      </i>
      <i
        v-else
        class="fa fa-circle unsaved-icon"
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
    </div>
  </li>
</template>
