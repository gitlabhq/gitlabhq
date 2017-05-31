/* eslint-disable class-methods-use-this */
import Vue from 'vue';
import VueResource from 'vue-resource';

import TeamDashboardMock from '../teamdashboard_mock';

Vue.use(VueResource);

export default class TeamDashboardService {
  constructor(groupId) {
    this.groupId = groupId;
    this.group = Vue.resource(`[[API]]/groups/${groupId}`);
    this.groupMembers = Vue.resource(`[[API]]/groups/${groupId}/members`);

    this.milestones = Vue.resource(`[[API]]/groups/${groupId}/milestones`);
  }

  getGroupInfo() {
    return this.group.get();
  }

  getGroupMembers() {
    return this.groupMembers.get();
  }

  getMilestones(project) {
    return Vue.http.get(`[[API]]/projects/${encodeURIComponent(project)}/milestones?per_page=200`);
  }

  getGroupConfiguration() {
    // return Vue.http.get(`/app/assets/javascripts/teamdashboard/data/${this.groupId}.json`);
    return TeamDashboardMock[this.groupId];
  }

  getProjectMilestoneDeliverables(project, milestone, defaultLabels) {
    return Vue.http.get(`[[API]]/projects/${encodeURIComponent(project)}/issues?milestone=${milestone}&labels=${defaultLabels}&per_page=200`);
  }

  getFolderContent(folderUrl) {
    return Vue.http.get(`${folderUrl}.json?per_page=${this.folderResults}`);
  }
}
