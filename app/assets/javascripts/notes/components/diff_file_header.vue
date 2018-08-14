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
  },
  computed: {
    titleTag() {
      return this.diffFile.discussionPath ? 'a' : 'span';
    },
  },
};
</script>

<template>
  <div class="file-header-content">
    <div
      v-if="diffFile.submodule"
    >
      <span>
        <icon name="archive" />
        <strong
          class="file-title-name"
          v-html="diffFile.submoduleLink"
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
        :href="diffFile.discussionPath"
      >
        <span v-html="diffFile.blobIcon"></span>
        <span v-if="diffFile.renamedFile">
          <strong
            :title="diffFile.oldPath"
            class="file-title-name has-tooltip"
            data-container="body"
          >
            {{ diffFile.oldPath }}
          </strong>
          &rarr;
          <strong
            :title="diffFile.newPath"
            class="file-title-name has-tooltip"
            data-container="body"
          >
            {{ diffFile.newPath }}
          </strong>
        </span>

        <strong
          v-else
          :title="diffFile.oldPath"
          class="file-title-name has-tooltip"
          data-container="body"
        >
          {{ diffFile.filePath }}
          <span v-if="diffFile.deletedFile">
            deleted
          </span>
        </strong>
      </component>

      <clipboard-button
        :text="diffFile.filePath"
        title="Copy file path to clipboard"
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
