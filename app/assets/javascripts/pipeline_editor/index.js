import Vue from 'vue';
import PipelineEditorApp from './pipeline_editor_app.vue';

export const initPipelineEditor = (selector = '#js-pipeline-editor') => {
  const el = document.querySelector(selector);

  return new Vue({
    el,
    render(h) {
      return h(PipelineEditorApp);
    },
  });
};
