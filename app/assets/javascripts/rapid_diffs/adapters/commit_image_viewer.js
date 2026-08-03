import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ImageViewer from '~/rapid_diffs/app/image_viewer/image_diff_viewer_with_discussions.vue';
import { commitDiffDiscussionsStore } from '~/rapid_diffs/stores/instances/commit_discussions';
import { MOUNTED } from '../adapter_events';

export const commitImageViewerAdapter = {
  [MOUNTED]() {
    const imageData = JSON.parse(
      this.diffElement.querySelector('[data-image-data]').dataset.imageData,
    );
    const { oldPath, newPath, diffRefs } = this.data;
    const { appData } = this;
    initVueApp({
      el: this.diffElement.querySelector('[data-image-view]'),
      name: 'ImageViewerRoot',
      provide() {
        return {
          store: commitDiffDiscussionsStore,
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
      component: ImageViewer,
      props: {
        imageData,
        oldPath,
        newPath,
        diffRefs,
      },
    });
  },
};
