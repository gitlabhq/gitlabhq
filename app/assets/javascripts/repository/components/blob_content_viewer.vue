<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import createFlash from '~/flash';
import { __ } from '~/locale';
import blobInfoQuery from '../queries/blob_info.query.graphql';

export default {
  components: {
    BlobHeader,
    BlobContent,
    GlLoadingIcon,
  },
  apollo: {
    project: {
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
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      project: {
        repository: {
          blobs: {
            nodes: [
              {
                name: '',
                size: '',
                rawTextBlob: '',
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
                simpleViewer: {},
                richViewer: {},
              },
            ],
          },
        },
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
    blobInfo() {
      const nodes = this.project?.repository?.blobs?.nodes;

      return nodes[0] || {};
    },
    viewer() {
      const viewer = this.blobInfo.richViewer || this.blobInfo.simpleViewer;
      const { fileType, tooLarge, type } = viewer;

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
        :content="blobInfo.rawTextBlob"
        :is-raw-content="true"
        :active-viewer="viewer"
        :loading="false"
      />
    </div>
  </div>
</template>
