<script>
  import { mapActions, mapState } from 'vuex';

  export default {
    props: {
      projectId: {
        type: String,
        required: true,
      },
      branchId: {
        type: String,
        required: true,
      },
      parent: {
        type: Object,
        default: null,
      },
    },
    computed: {
      ...mapState([
        'trees',
      ]),
    },
    methods: {
      ...mapActions([
        'createTempEntry',
      ]),
      createFile(target, file, isText) {
        const { name } = file;
        let { result } = target;

        if (!isText) {
          result = result.split('base64,')[1];
        }

        this.createTempEntry({
          name,
          projectId: this.projectId,
          branchId: this.branchId,
          parent: this.parent,
          type: 'blob',
          content: result,
          base64: !isText,
        });
      },
      readFile(file) {
        const reader = new FileReader();
        const isText = file.type.match(/text.*/) !== null;

        reader.addEventListener('load', e => this.createFile(e.target, file, isText), { once: true });

        if (isText) {
          reader.readAsText(file);
        } else {
          reader.readAsDataURL(file);
        }
      },
      openFile() {
        Array.from(this.$refs.fileUpload.files).forEach(file => this.readFile(file));
      },
      startFileUpload() {
        this.$refs.fileUpload.click();
      },
    },
    mounted() {
      this.$refs.fileUpload.addEventListener('change', this.openFile);
    },
    beforeDestroy() {
      this.$refs.fileUpload.removeEventListener('change', this.openFile);
    },
  };
</script>

<template>
  <div>
    <a
      href="#"
      role="button"
      @click.prevent="startFileUpload"
    >
      {{ __('Upload file') }}
    </a>
    <input
      id="file-upload"
      type="file"
      class="hidden"
      ref="fileUpload"
    />
  </div>
</template>
