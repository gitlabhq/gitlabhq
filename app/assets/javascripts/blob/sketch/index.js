import Vue from 'vue';
import VueResource from 'vue-resource';
import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';

Vue.use(VueResource);

export default () => {
  const el = document.getElementById('js-sketch-viewer');


  new Vue({
    el,
    data(){
      return {
        previewURL: '',
        error: false
      }
    },

    methods: {

      tryUnzip() {
        return this.$http.get(el.dataset.endpoint)
        // return new JSZip.external.Promise((resolve, reject) => {
        //   JSZipUtils.getBinaryContent(el.dataset.endpoint, (err, data) => {
        //     if (err) {
        //       reject(err);
        //     } else {
        //       resolve(data);
        //     }
        //   });
        // });

      }
    },

    mounted() {
      this.tryUnzip()
      .then((res) => {
        JSZip.loadAsync(res)
        .then((something) => {
          console.log(something);
        })
      })
      // .then((data) =>{
      //   return JSZip.loadAsync(data);
      // })
      // .then((something) => {
      //   something.files['previews/preview.png'].async('uint8array')
      //   .then((content)=>{
      //     var fileReader = new FileReader();
      //     var blob = new Blob(content, {type: 'image/png'});
      //     var url = URL.createObjectURL(blob);

      //     this.previewURL = url;
      //   });
      // });
    },

    template: `
      <div>
        <img :src=previewURL />
      </div>
    `
  });
}