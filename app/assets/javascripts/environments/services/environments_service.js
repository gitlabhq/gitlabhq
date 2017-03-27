/* eslint-disable class-methods-use-this */
import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class EnvironmentsService {
  constructor(endpoint) {
    /**
     * FIX ME: This should be sent by backend.
     */
    const customActions = {
      folderContent: { method: 'GET', url: `${window.location.pathname}/folders{/name}?perPage=2` },
    };

    this.environments = Vue.resource(endpoint, {}, customActions);
  }

  get(scope, page) {
    return this.environments.get({ scope, page });
  }

  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }

  getFolderContent(folderName) {
    debugger
    return this.environments.folderContent({ name: folderName });
  }
}
