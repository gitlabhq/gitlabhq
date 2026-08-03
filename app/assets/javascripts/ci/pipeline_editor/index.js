import Vue from 'vue';
import { GlToast } from '@gitlab/ui';

import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { createAppOptions } from '~/ci/pipeline_editor/options';

export const initPipelineEditor = (selector = '#js-pipeline-editor') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  Vue.use(GlToast);

  const options = createAppOptions(el);

  return initVueApp(options);
};

initPipelineEditor();
