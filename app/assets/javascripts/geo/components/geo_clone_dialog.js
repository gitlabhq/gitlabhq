/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.geo = window.gl.geo || {};

  window.gl.geo.CloneDialog = Vue.extend({
    props: ['title', 'id'],
    data() {
      return this.$parent.$data;
    },
    mounted() {
      $(`#${this.id}`).appendTo('body').modal({ modal: true, show: false });
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
                      <p><strong>Step 1.</strong> Clone the repository from your secondary node:</p> 
                      <slot name="clipboard-1"></slot>
                      <pre class="dark" id="geo-info-1">git clone {{cloneUrlSecondary}}</pre>
                      
                      <p><strong>Step 2.</strong> Go to the new directory and define <strong>primary node's</strong> repository URL as the <strong>push</strong> remote:</p>
                      <slot name="clipboard-2"></slot>
                      <pre class="dark" id="geo-info-2">git remote set-url --push origin {{cloneUrlPrimary || '&lt;clone url for primary repository&gt;'}}</pre> 
                      <p><strong>Done.</strong> You can now commit and push code as you normally do, but with increased speed.</p>
                  </div>
              </div>
          </div>
      </div>
        `,
  });
})();
