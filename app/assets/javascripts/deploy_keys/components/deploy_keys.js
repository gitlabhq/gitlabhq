import Vue from 'vue';
import DeployKeysService from '../services/deploy_keys_service';
import DeployKey from './deploy_key';

//     // TODO: @deploy_keys.key_available?(deploy_key)
//     // Enable/remove/disable

export default Vue.component('deploy-keys', {
  data() {
    return {
      loaded: false,
      sections: [{
        title: 'Enabled deploy keys for this project',
        keys: [],
        alwaysRender: true,
      }, {
        title: 'Deploy keys from projects you have access to',
        keys: [],
        alwaysRender: true,
      }, {
        title: 'Public deploy keys available to any project',
        keys: [],
        alwaysRender: false,
      }],
    };
  },

  created() {
    this.service = new DeployKeysService('../deploy_keys.json?type=enabled');

    this.service.get().then((response) => {
      const data = response.data;
      this.sections[0].keys = data.enabled_keys;
      this.sections[1].keys = data.available_project_keys;
      this.sections[2].keys = data.public_keys;
      console.log(response.data);

      this.loaded = true;
    });
  },
  components: {
    'deploy-key': DeployKey,
  },
  template: `
    <div>
      <template
        v-for="(section, index) in sections"
        v-if="section.alwaysRender || !section.alwaysRender && section.keys.length > 0"
      >
        <h5 :class="{'prepend-top-0': index === 0, 'prepend-top-default': index !== 0}">
          {{section.title}}
          <template v-if="loaded">({{section.keys.length}})</template>
        </h5>
        <ul class="well-list" v-if="loaded && section.keys.length > 0">
          <deploy-key
            v-for="key in section.keys"
            :title="key.title"
            :fingerprint="key.fingerprint"
            :projects="key.projects"
            :canPush="key.can_push"
            :createdAt="key.created_at"
          />
        </ul>
        <div
          v-else-if="loaded && section.keys.length === 0"
          class="settings-message text-center"
        >
          No deploy keys found. Create one with the form above.
        </div>
        <div v-else>
          <i class="fa fa-spin fa-spinner" aria-label="loading" />
        </div>
      </template>
    </div>
  `,
});
