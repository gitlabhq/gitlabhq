<script>
  import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
  import Icon from '~/vue_shared/components/icon.vue';

  export default {
    props: {
      diffFile: {
        type: Object,
        required: true,
      },
    },
    components: {
      ClipboardButton,
      Icon,
    },
    computed: {

    },
  };
</script>

<template>
  <div class="file-header-content">
    <div
      v-if="diffFile.submodule"
    >
      <span>
        <Icon name="archive" />
        <strong
          v-html="diffFile.submoduleLink"
          class="file-title-name"
        />
        <clipboard-button
          text="Copy file path to clipboard"
          :title="diffFile.submoduleLink"
        />
      </span>
    </div>
    <component
      v-else
      is="a"
    >
      <i class="fa fw" :class="diffFile.fileTypeIcon" />
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

      <clipboard-button
        title="Copy file path to clipboard"
        :text="diffFile.filePath"
      />

      <small v-if="diffFile.modeChanged" ref="fileMode">
        {{diffFile.aMode}} → {{diffFile.bMode}}
      </small>
    </component>
  </div>
</template>
