<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import createFlash from '~/flash';
import { __ } from '~/locale';
import blobInfoQuery from '../queries/blob_info.query.graphql';
import projectPathQuery from '../queries/project_path.query.graphql';

export default {
  components: {
    BlobHeader,
    BlobContent,
    GlLoadingIcon,
  },
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
    blobInfo: {
      query: blobInfoQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.path,
        };
      },
      error() {
        createFlash({ message: __('An error occurred while loading the file. Please try again.') });
      },
    },
  },
  provide() {
    return {
      blobHash: uniqueId(),
    };
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      projectPath: '',
      blobInfo: {
        name: '',
        size: '',
        rawBlob: '',
        type: '',
        fileType: '',
        tooLarge: false,
        path: '',
        editBlobPath: '',
        ideEditPath: '',
        storedExternally: false,
        rawPath: '',
        externalStorageUrl: '',
        replacePath: '',
        deletePath: '',
        canLock: false,
        isLocked: false,
        lockLink: '',
        canModifyBlob: true,
        forkPath: '',
        simpleViewer: '',
        richViewer: '',
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.blobInfo.loading;
    },
    viewer() {
      const { fileType, tooLarge, type } = this.blobInfo;

      return { fileType, tooLarge, type };
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" />
    <div v-if="blobInfo && !isLoading">
      <blob-header :blob="blobInfo" />
      <blob-content
        :blob="blobInfo"
        :content="blobInfo.rawBlob"
        :is-raw-content="true"
        :active-viewer="viewer"
        :loading="false"
      />
    </div>
  </div>
</template>
