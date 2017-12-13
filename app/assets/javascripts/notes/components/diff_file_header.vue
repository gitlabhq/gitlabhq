<script>
  const diffFile = {
    submodule: false,
    submoduleLink: '<a href="/bha">Submodule</a>', // submodule_link(blob, diff_file.content_sha, diff_file.repository)
    url: '',
    renamedFile: false,
    deletedFile: false,
    modeChanged: false,
    bMode: false, // TODO: check type
    filePath: '/some/file/path',
    oldPath: '',
    newPath: '',
    fileTypeIcon: 'fa-file-image-o', // file_type_icon_class('file', diff_file.b_mode, diff_file.file_path)
  }

  const CopyToClipboardBtn = {
    template: '<button>Copy</button>'
  }

  import Icon from '~/vue_shared/components/icon.vue';

  export default {
    props: {
    },
    components: {
      Icon,
      CopyToClipboardBtn,
    },
    data() {
      return {
        showToggle: false,
        diffFile,
      };
    },
    computed: {

    },
  };
</script>

<template>
  <div class="file-header-content">
    <i
      class="fa diff-toggle-caret fa-fw"
      v-if="showToggle"
    />
    <div
      v-if="diffFile.submodule"
    >
      <span>
        <Icon name="archive" />
        <strong
          v-html="submoduleLink"
          class="file-title-name"
        />
        <!-- TODO: this onclick: = copy_file_path_button(blob.path) -->
        <Icon name="copy" />
      </span>
    </div>
    <component
      v-else
      is="a"
    >
      <!-- Icon :name="diffFile.fileTypeIcon" / -->
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

      <copy-to-clipboard-btn
        :text="diffFile.filePath"
      />

      <small v-if="diffFile.modeChanged">
        #{diffFile.aMode} → #{diffFile.bMode}
      </small>
    </component>
  </div>
</template>
