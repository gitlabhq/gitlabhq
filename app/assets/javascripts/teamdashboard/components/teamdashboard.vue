<script>
import TeamDashboardStore from '../stores/teamdashboard_store.js';
import TeamDashboardService from '../services/teamdashboard_service.js';

import TeamMemberItem from './teammember_item.vue';
import IssueList from './issue_list.vue';
import CalendarLine from './calendarline.vue';
import SimulationPanel from './teamdashboard_simulation_panel.vue';

import '../../lib/utils/datetime_utility';

export default {
  /**  
   * Although most data belongs in the store, each component it's own state.
   * We want to show a loading spinner while we are fetching the todos, this state belong
   * in the component.
   *
   * We need to access the store methods through all methods of our component.
   * We need to access the state of our store.
   */   
  data() {
    const store = new TeamDashboardStore();

    return {
      store,
      milestone: '',
      milestoneInfo: {},
      groupInfo: store.groupInfo,
      groupMembers: store.groupMembers,
      groupConfiguration: store.groupConfiguration,
      deliverableInfo: store.deliverableInfo,
      isLoading: false,
      loadingStatus: ''
    };
  },

  components: {
    TeamMemberItem,
    IssueList,
    CalendarLine,
    SimulationPanel,
  },

  created() {
    const groupId = (window.gl.target === 'local') ? 56 : 'gl-frontend';
    this.service = new TeamDashboardService(groupId);

    this.isLoading = true;
    this.loadingStatus = 'Group';

    this.fetchGroup()
      .then(()=> {
        this.loadingStatus = 'Group Members';
        this.fetchGroupMembers().
          then(() => {
            this.fetchGroupConfiguration();

            this.milestone = this.store.groupConfiguration.currentMilestone;
            

            let currentProject = this.store.groupConfiguration.projects[0];

            this.loadingStatus = 'Milestones';
            this.fetchMilestones(currentProject).
              then(() => {

                this.milestoneInfo = _.findWhere(this.store.milestones,{title:this.milestone});
                console.log('Milestone : ',this.milestoneInfo);

                this.loadingStatus = 'Deliverables';
                this.fetchProjectMilestoneIssues(currentProject,this.milestone, this.store.groupConfiguration.groupIdentityLabels.join(','))
                  .then(() => {
                    this.isLoading = false;
                  });    
              });                        
          });        
      });

    
  },  

  methods: {
    fetchGroup() {
      return this.service.getGroupInfo()
        .then(response => response.json())
        .then((response) => {
          this.store.storeGroupInfo(response);         
        })
        .catch(() => {
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the group info.');
        });
    },
    fetchGroupConfiguration() {
      /*
        return this.service.getGroupConfiguration()
          .then((response) => {
            this.store.storeGroupConfiguration(response)
          });
          */
          //As this is currently a mock implementation its synchronous
          this.store.storeGroupConfiguration(this.service.getGroupConfiguration());
    },
    fetchGroupMembers() {
      return this.service.getGroupMembers()
        .then(response => response.json())
        .then((response) => {
          this.store.storeGroupMembers(response);          
        })
        .catch(() => {
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the group members.');
        });
    },
    fetchMilestones(project) {
      return this.service.getMilestones(project)
        .then(response => response.json())
        .then((response) => {
          this.store.storeMilestones(response);          
        })
        .catch(() => {
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the milestones.');
        });
    },
    fetchProjectMilestoneIssues(project, milestone, defaultLabels) {
      return this.service.getProjectMilestoneDeliverables(project, milestone, defaultLabels)
        .then(response => response.json())
        .then((response) => {
          this.store.storeMilestoneDeliverables(response);          
        })
        .catch(() => {
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the group deliverables.');
        });
    },
    formatShortDate(selectedDate) {
      return dateFormat(selectedDate, 'mmm d, yyyy');
    }
  }
}
</script>
<template>
  <div class="container teamdashboard milestone-content">
    <div v-if="isLoading">

      <h4 class="text-center loading">Loading {{loadingStatus}} ... </h4>
    </div>    
    <div
      v-if="!isLoading && groupInfo">
      <div class="row">
        <div class="col-sm-8">
          <h5>Team {{store.groupInfo.name}}</h5>
          <h2>
            Release {{milestone}} <small>{{formatShortDate(milestoneInfo.start_date)}}-{{formatShortDate(milestoneInfo.due_date)}}</small>
          </h2>
        </div>
        <div class="col-sm-4">
          <div class="row">
            <div class="col-sm-4 text-center">
              <h2>{{deliverableInfo.doneDeliverables}} / {{store.milestoneDeliverables.length}}</h2>
              <small>Deliverables</small>
            </div>
            <div class="col-sm-4 text-center">
              <h2>4</h2>
              <small>Regressions</small>
            </div>
            <div class="col-sm-4 text-center">
              <h2>0</h2>
              <small>Blockers</small>
            </div>
          </div>
        </div>
      </div>

      <CalendarLine :milestone="milestoneInfo"/>

      <div v-if="store.nonAssignedMilestoneDeliverables.length>0" class="panel panel-default">
        <div class="panel-heading">
          <div class="title">
            <h4>{{ store.nonAssignedMilestoneDeliverables.length}} Unassigned Issues</h4>
          </div>
        </div>
        <!--<ul class="well-list issues-sortable-list" data-state="unassigned" id="issues-list-unassigned" style="min-height: 0px;">
          <li class="issuable-row " data-id="4057910" data-iid="27164" data-url="/gitlab-org/gitlab-ce/issues/27164" id="sortable_issue_4057910">
          <span>
          <a title="Projects::IssuesControllers#show is slow due to GIT and DB access" href="/gitlab-org/gitlab-ce/issues/27164">Projects::IssuesControllers#show is slow due to GIT and DB access</a>
          </span>
          <div class="issuable-detail">
          <a href="/gitlab-org/gitlab-ce/issues/27164"><span class="issuable-number">#27164</span>
          </a><a href="/gitlab-org/gitlab-ce/issues?label_name=backend&amp;milestone_title=9.3&amp;state=all"><span class="label color-label has-tooltip" style="background-color: #F0AD4E; color: #FFFFFF" title="Issues that require backend work" data-container="body">backend</span></a><a href="/gitlab-org/gitlab-ce/issues?label_name=Deliverable&amp;milestone_title=9.3&amp;state=all"><span class="label color-label has-tooltip" style="background-color: #428BCA; color: #FFFFFF" title="" data-container="body">Deliverable</span></a><a href="/gitlab-org/gitlab-ce/issues?label_name=issues&amp;milestone_title=9.3&amp;state=all"><span class="label color-label has-tooltip" style="background-color: #428bca; color: #FFFFFF" title="Issues related to managing issues, including milestones and labels" data-container="body">issues</span></a><a href="/gitlab-org/gitlab-ce/issues?label_name=Discussion&amp;milestone_title=9.3&amp;state=all"><span class="label color-label has-tooltip" style="background-color: #44ad8e; color: #FFFFFF" title="Issues for the Discussion team. Covers Issues, Merge Requests, Markdown, etc. PM: @victorwu" data-container="body">Discussion</span></a><a href="/gitlab-org/gitlab-ce/issues?label_name=performance&amp;milestone_title=9.3&amp;state=all"><span class="label color-label has-tooltip" style="background-color: #ff5f00; color: #FFFFFF" title="Issues related to GitLab's performance" data-container="body">performance</span></a><span class="assignee-icon">
          </span>
          </div>
          </li>
        </ul>-->
        <IssueList :issues="store.nonAssignedMilestoneDeliverables"/>
      </div>

      <div class="row">
        <template v-for="(groupMember, index) in store.groupMembers">
          <div :class="(index % 2 ? '' : 'left-col') + ' col-sm-6'">
          <TeamMemberItem :data="groupMember"/>
          </div>
        </template>
      </div>

      <SimulationPanel :store="store"/>
    </div>
  </div>
</template>
