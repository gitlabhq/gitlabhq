//= require vue
/* global modal */
(() => {
  Vue.component('geo-clone-dialog', {
    name: 'geo-clone-dialog',
    props: ['title', 'id'],
    data() {
      return this.$parent.$data;
    },
    mounted() {
      $(`#${this.id}`).appendTo('body').modal({ modal: true, show: false });
      $('.modal-header .close').bind('click', () => modal.hide());
    },
    filters: {
      emptyRepo: (value) => {
        if (!value) return '<clone url for primary repository>';
        return value;
      },
    },
    template: `
      <div class="modal in" tabindex="-1" :id="id">
          <div class="modal-dialog">
              <div class="modal-content">
                  <div class="modal-header">
                      <a href="#" data-dismiss="modal" class="close">×</a>
                      <h3>{{title}}</h3>
                  </div>
                  <div class="modal-body">
                      <p><strong>Step1.</strong> Clone the repository and define <strong>primary's node</strong> repository URL as target to push code:</p> 
                      <slot name="clipboard"></slot>
                      <pre class="dark" id="geo-info">git clone {{cloneUrlSecondary}}
git remote set-url --push origin {{cloneUrlPrimary | emptyRepo}}</pre>
                      <p><strong>Step2.</strong> Commit and push code as you normally do, but with increased speed.</p>
                  </div>
              </div>
          </div>
      </div>
        `,
  });

  document.addEventListener('DOMContentLoaded', () => {
    gl.GeoCloneDialog = new Vue({
      el: '#geo_clone',
      data: Object.assign({}, document.getElementById('geo_clone').dataset),
    });
  });
})(window.gl || (window.gl = {}));
