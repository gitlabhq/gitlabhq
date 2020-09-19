import Vue from 'vue';
import WebIdeAlert from './components/web_ide_alert.vue';

export default el => {
  const { dismissEndpoint, featureId, editPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(WebIdeAlert, {
        props: {
          dismissEndpoint,
          featureId,
          editPath,
        },
      });
    },
  });
};
