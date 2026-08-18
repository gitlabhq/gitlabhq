import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import MrWidgetHowToMergeModal from '~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue';

export default () => {
  const modalEl = document.getElementById('js-check-out-modal');

  if (!modalEl) return false;

  const { isFork, sourceBranch, sourceProjectPath, sourceProjectDefaultUrl, reviewingDocsPath } =
    modalEl.dataset;

  return initVueApp({
    el: modalEl,
    name: 'MrWidgetHowToMergeModalRoot',
    component: MrWidgetHowToMergeModal,
    props: {
      isFork: parseBoolean(isFork),
      sourceBranch,
      sourceProjectPath,
      sourceProjectDefaultUrl,
      reviewingDocsPath,
    },
  });
};
