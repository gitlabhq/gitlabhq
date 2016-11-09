/*= require vue
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  window.gl.environmentsList.ActionsComponent = Vue.component('actions-component', {
    props: {
      actions: {
        type: Array,
        required: false,
        default: () => []
      }
    },
    
    template: `
      <div class="inline">
        <div class="dropdown">
          <a class="dropdown-new btn btn-default" data-toggle="dropdown">
            playIcon
            <i class="fa fa-caret-down"></i>
          </a>
          
          <ul class="dropdown-menu dropdown-menu-align-right">
            <li v-for="action in actions">
              <a :href="action.play_url" data-method="post" rel="nofollow">
                icon play
                <span>
                  {{action.name}}
                </span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    `
  }); 
})();