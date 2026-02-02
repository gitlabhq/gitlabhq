import Vue from 'vue';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue';
import { MOUNTED } from '../adapter_events';

export const commitImageViewerAdapter = {
  [MOUNTED]() {
    const imageData = JSON.parse(
      this.diffElement.querySelector('[data-image-data]').dataset.imageData,
    );
    const { oldPath, newPath } = this.data;
    const { appData } = this;
    // eslint-disable-next-line no-new
    new Vue({
      el: this.diffElement.querySelector('[data-image-view]'),
      name: 'ImageViewerRoot',
      provide() {
        return {
          userPermissions: appData.userPermissions,
          endpoints: {
            discussions: appData.discussionsEndpoint,
            previewMarkdown: appData.previewMarkdownEndpoint,
            markdownDocs: appData.markdownDocsEndpoint,
            register: appData.registerPath,
            signIn: appData.signInPath,
            reportAbuse: appData.reportAbusePath,
          },
          noteableType: appData.noteableType,
        };
      },
      render(h) {
        return h(ImageViewer, {
          props: {
            imageData,
            oldPath,
            newPath,
          },
        });
      },
    });
  },
};
