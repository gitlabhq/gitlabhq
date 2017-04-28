/* eslint-disable no-new */
import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class SettingsDeployKeys {
  constructor() {
    this.initVue();
  }

  deployKeyRowTemplate() {
    return `
      <li>
        <div class="pull-left append-right-10 hidden-xs">
          <i aria-hidden="true" class="fa fa-key key-icon"></i>
        </div>
        <div class="deploy-key-content key-list-item-info">
          <strong class="title">
            {{deployKey.title}}
          </strong>
          <div class="description">
            {{deployKey.fingerprint}}
          </div>
        </div>
        <div class="deploy-key-content prepend-left-default deploy-key-projects">
          <a class="label deploy-project-label" :href="project.full_path" v-for="project in deployKey.projects">{{project.full_name}}</a>
        </div>
        <div class="deploy-key-content">
          <span class="key-created-at">
            created {{deployKey.created_at}}
          </span>
          <div class="visible-xs-block visible-sm-block"></div>
          <a v-if="!enabled" class="btn btn-sm prepend-left-10" rel="nofollow" data-method="put" href="enableURL">Enable
</a>
          <a v-else-if="deployKey.destroyed_when_orphaned && deployKey.almost_orphaned" class="btn btn-warning btn-sm prepend-left-10" rel="nofollow" data-method="put" :href="removeURL">Remove</a>
          <a v-else class="btn btn-warning btn-sm prepend-left-10" rel="nofollow" data-method="put" :href="disableURL">Disable</a>
        </div>
      </li>`
  }

  deployKeyRowComponent() {
    const self = this;
    return {
      props: {
        deployKey: Object,
        enabled: Boolean
      },

      computed: {
        disableURL() {
          return self.disableEndpoint.replace(':id', this.deployKey.id);
        },

        enableURL() {
         return self.enableEndpoint.replace(':id', this.deployKey.id); 
        }
      },

      template: this.deployKeyRowTemplate()
    }
  }

  initVue() {
    const self = this;
    const el = document.getElementById('js-deploy-keys');
    const endpoint = el.dataset.endpoint;
    this.jsonEndpoint = `${endpoint}.json`;
    this.disableEndpoint = `${endpoint}/:id/disable`;
    this.enableEndpoint = `${endpoint}/:id/enable`;
    new Vue({
      el: el,
      components: {
        deployKeyRow: self.deployKeyRowComponent()
      },
      data () {
        return {
          enabledKeys: [],
          availableKeys: []
        }
      },
      created () {
        this.$http.get(self.jsonEndpoint)
          .then((res) => {
            const keys = JSON.parse(res.body);
            this.enabledKeys = keys.enabled_keys;
            this.availableKeys = keys.available_project_keys;
          });
      }
    })
  }
} 