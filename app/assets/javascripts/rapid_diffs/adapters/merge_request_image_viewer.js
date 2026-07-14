import Vue from 'vue';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { pinia } from '~/pinia/instance';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { MOUNTED } from '../adapter_events';

export const mergeRequestImageViewerAdapter = {
  [MOUNTED]() {
    const imageData = JSON.parse(
      this.diffElement.querySelector('[data-image-data]').dataset.imageData,
    );
    const { oldPath, newPath, diffRefs } = this.data;
    const { appData } = this;
    // eslint-disable-next-line no-new
    new Vue({
      el: this.diffElement.querySelector('[data-image-view]'),
      pinia,
      apolloProvider,
      name: 'ImageViewerRoot',
      provide() {
        return {
          store: useMergeRequestDiscussions(pinia),
          userPermissions: appData.userPermissions,
          sourceBranch: appData.sourceBranch,
          iid: appData.iid,
          endpoints: {
            discussions: appData.discussionsEndpoint,
            previewMarkdown: appData.previewMarkdownEndpoint,
            markdownDocs: appData.markdownDocsEndpoint,
            register: appData.registerPath,
            signIn: appData.signInPath,
            reportAbuse: appData.reportAbusePath,
          },
          noteableType: appData.noteableType,
          filePaths: { oldPath, newPath },
          newCommentTemplatePaths: appData.newCommentTemplatePaths || [],
        };
      },
      render(h) {
        return h(ImageViewer, {
          props: {
            imageData,
            oldPath,
            newPath,
            diffRefs,
          },
        });
      },
    });
  },
};
