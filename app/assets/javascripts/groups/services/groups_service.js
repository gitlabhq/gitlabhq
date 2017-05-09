import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class GroupsService {
  constructor(endpoint) {
    this.groups = Vue.resource(endpoint);
  }

  getGroups() {
    return this.groups.get();
  }

  getFakeGroups() {
    return [{
        "id":1118,
        "name":"tortor",
        "path":"tortor",
        "description":"",
        "visibility":"private",
        "web_url":"http://localhost:3000/groups/tortor",
        "full_name":"tortor",
        "full_path":"tortor",
        "parent_id":null,
        "subGroups": [], 
        "isOpen": false,
     },
     {
        "id":1117,
        "name":"enot",
        "path":"enot",
        "description":"",
        "visibility":"private",
        "web_url":"http://localhost:3000/groups/enot",
        "full_name":"enot",
        "full_path":"enot",
        "parent_id":null,
        "isOpen": false,
        "subGroups": [{
          "id":1120,
          "name":"tortor",
          "path":"tortor",
          "description":"",
          "visibility":"private",
          "web_url":"http://localhost:3000/groups/tortor",
          "full_name":"tortor",
          "full_path":"tortor",
          "parent_id":null,
          "subGroups": [],
          "isOpen": false,
        }],
     }];
  }
}
