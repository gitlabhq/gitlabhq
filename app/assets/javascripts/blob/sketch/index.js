import Vue from 'vue';
import VueResource from 'vue-resource';
import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';

Vue.use(VueResource);

export default () => {
  const el = document.getElementById('js-sketch-viewer');

  return new Vue({
    el,
    data() {
      return {
        previewURL: '',
        error: false,
      };
    },
    methods: {
      tryUnzip() {
        return new JSZip.external.Promise((resolve, reject) => {
          JSZipUtils.getBinaryContent(el.dataset.endpoint, (err, data) => {
            if (err) {
              reject(err);
            } else {
              resolve(data);
            }
          });
        });
      },
    },
    mounted() {
      this.tryUnzip()
        .then(data => JSZip.loadAsync(data))
        .then((asyncResult) => {
          asyncResult.files['previews/preview.png'].async('uint8array')
            .then((content) => {
              const url = window.URL || window.webkitURL;
              const blob = new Blob([new Uint8Array(content)], { type: 'image/png' });
              const previewUrl = url.createObjectURL(blob);

              this.previewURL = previewUrl;
            });
        });
    },
    template: `
      <div>
        <img :src=previewURL />
      </div>
    `,
  });
};
