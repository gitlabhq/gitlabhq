import Vue from 'vue';

import { createAppOptions } from '~/ci/pipeline_editor/options';

export const initPipelineEditor = (selector = '#js-pipeline-editor') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const options = createAppOptions(el);

  return new Vue(options);
};

initPipelineEditor();
