<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    ClipboardButton,
    Icon,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    collapsible: {
      type: Boolean,
      required: false,
      default: false,
    },
    addMergeRequestButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    titleTag() {
      return this.diffFile.fileHash ? 'a' : 'span';
    },
  },
  methods: {
    handleToggle(e, checkTarget) {
      if (checkTarget) {
        if (e.target === this.$refs.header) {
          this.$emit('toggleFile');
        }
      } else {
        this.$emit('toggleFile');
      }
    },
  },
};
</script>

<template>
  <div
    @click="handleToggle($event, true)"
    ref="header"
    class="file-header-content"
  >
    <i
      v-if="collapsible"
      @click.stop="handleToggle"
      class="fa diff-toggle-caret fa-fw fa-caret-down"
    ></i>
    <div
      v-if="diffFile.submodule"
    >
      <span>
        <icon name="archive" />
        <strong
          v-html="diffFile.submoduleLink"
          class="file-title-name"
        ></strong>
        <clipboard-button
          :text="diffFile.submoduleLink"
          title="Copy file path to clipboard"
          css-class="btn-default btn-transparent btn-clipboard"
        />
      </span>
    </div>
    <template v-else>
      <component
        ref="titleWrapper"
        :is="titleTag"
        :href="`#${diffFile.fileHash}`"
      >
        <span v-html="diffFile.blobIcon"></span>
        <span v-if="diffFile.renamedFile">
          <strong
            class="file-title-name has-tooltip"
            :title="diffFile.oldPath"
            data-container="body"
          >
            {{ diffFile.oldPath }}
          </strong>
          &rarr;
          <strong
            class="file-title-name has-tooltip"
            :title="diffFile.newPath"
            data-container="body"
          >
            {{ diffFile.newPath }}
          </strong>
        </span>

        <strong
          v-else
          class="file-title-name has-tooltip"
          :title="diffFile.oldPath"
          data-container="body"
        >
          {{ diffFile.filePath }}
          <span v-if="diffFile.deletedFile">
            deleted
          </span>
        </strong>
      </component>

      <clipboard-button
        title="Copy file path to clipboard"
        :text="diffFile.filePath"
        css-class="btn-default btn-transparent btn-clipboard"
      />

      <small
        v-if="diffFile.modeChanged"
        ref="fileMode"
      >
        {{ diffFile.aMode }} → {{ diffFile.bMode }}
      </small>
    </template>
  </div>
</template>
