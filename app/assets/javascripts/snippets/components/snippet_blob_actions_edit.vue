<script>
import { GlButton, GlFormGroup } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { s__, sprintf } from '~/locale';
import { SNIPPET_MAX_BLOBS, SNIPPET_LIMITATIONS } from '../constants';
import { createBlob, decorateBlob, diffAll } from '../utils/blob';
import SnippetBlobEdit from './snippet_blob_edit.vue';

export default {
  components: {
    SnippetBlobEdit,
    GlButton,
    GlFormGroup,
  },
  props: {
    initBlobs: {
      type: Array,
      required: true,
    },
    isValid: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      // This is a dictionary (by .id) of the original blobs and
      // is used as the baseline for calculating diffs
      // (e.g., what has been deleted, changed, renamed, etc.)
      blobsOrig: {},
      // This is a dictionary (by .id) of the current blobs and
      // is updated as the user makes changes.
      blobs: {},
      // This is a list of blob ID's in order how they should be
      // presented.
      blobIds: [],
    };
  },
  computed: {
    actions() {
      return diffAll(this.blobs, this.blobsOrig);
    },
    count() {
      return this.blobIds.length;
    },
    addLabel() {
      return sprintf(s__('Snippets|Add another file %{num}/%{total}'), {
        num: this.count,
        total: SNIPPET_MAX_BLOBS,
      });
    },
    limitationText() {
      return sprintf(SNIPPET_LIMITATIONS, {
        total: SNIPPET_MAX_BLOBS,
      });
    },
    canDelete() {
      return this.count > 1;
    },
    canAdd() {
      return this.count < SNIPPET_MAX_BLOBS;
    },
    firstInputId() {
      const blobId = this.blobIds[0];

      if (!blobId) {
        return '';
      }

      return `${blobId}_file_path`;
    },
  },
  watch: {
    actions: {
      immediate: true,
      handler(val) {
        this.$emit('actions', val);
      },
    },
  },
  created() {
    const blobs = this.initBlobs.map(decorateBlob);
    const blobsById = blobs.reduce((acc, x) => Object.assign(acc, { [x.id]: x }), {});

    this.blobsOrig = blobsById;
    this.blobs = cloneDeep(blobsById);
    this.blobIds = blobs.map((x) => x.id);

    // Show 1 empty blob if none exist
    if (!this.blobIds.length) {
      this.addBlob();
    }
  },
  methods: {
    updateBlobContent(id, content) {
      const origBlob = this.blobsOrig[id];
      const blob = this.blobs[id];

      blob.content = content;

      // If we've received content, but we haven't loaded the content before
      // then this is also the original content.
      if (origBlob && !origBlob.isLoaded) {
        blob.isLoaded = true;
        origBlob.isLoaded = true;
        origBlob.content = content;
      }
    },
    updateBlobFilePath(id, path) {
      const blob = this.blobs[id];

      blob.path = path;
    },
    addBlob() {
      const blob = createBlob();

      this.blobs = {
        ...this.blobs,
        [blob.id]: blob,
      };
      this.blobIds.push(blob.id);
    },
    deleteBlob(id) {
      this.blobIds = this.blobIds.filter((x) => x !== id);
      const copy = { ...this.blobs };
      delete copy[id];
      this.blobs = copy;
    },
    updateBlob(id, args) {
      if ('content' in args) {
        this.updateBlobContent(id, args.content);
      }
      if ('path' in args) {
        this.updateBlobFilePath(id, args.path);
      }
    },
  },
};
</script>
<template>
  <div class="form-group">
    <gl-form-group
      :label="s__('Snippets|Files')"
      :label-for="firstInputId"
      :invalid-feedback="
        s__(
          'Snippets|Snippets can\'t contain empty files. Ensure all files have content, or delete them.',
        )
      "
      :state="isValid"
    >
      <snippet-blob-edit
        v-for="(blobId, index) in blobIds"
        :key="blobId"
        :class="{ 'gl-mt-3': index > 0 }"
        :blob="blobs[blobId]"
        :can-delete="canDelete"
        @blob-updated="updateBlob(blobId, $event)"
        @delete="deleteBlob(blobId)"
      />
    </gl-form-group>
    <gl-button
      :disabled="!canAdd"
      data-testid="add-button"
      class="gl-my-3"
      variant="dashed"
      @click="addBlob"
      >{{ addLabel }}</gl-button
    >
    <p v-if="!canAdd" data-testid="limitations_text" class="gl-text-subtle">
      {{ limitationText }}
    </p>
  </div>
</template>
