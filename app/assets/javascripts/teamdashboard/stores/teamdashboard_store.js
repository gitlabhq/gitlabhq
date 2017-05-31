import '~/lib/utils/common_utils';
/**
 * Team Dashboard Store.
 *
 * Stores the selected group, group members, issues
 */
export default class TeamDashboardStore {
  constructor() {
    this.groupInfo = {};
    this.groupMembers = [];
    this.groupConfiguration = {};

    this.milestones = [];

    this.milestoneDeliverables = [];
    this.nonAssignedMilestoneDeliverables = [];

    this.deliverableInfo = {
      doneDeliverables: 0,
    };

    this.blockerIssues = [];
    this.regressionIssues = [];

    return this;
  }

  storeGroupInfo(groupInfo) {
    this.groupInfo = groupInfo;
    return groupInfo;
  }

  storeGroupMembers(groupMembers) {
    this.groupMembers = _.sortBy(groupMembers, 'name');
    this.groupMembers.forEach((member) => {
      member.deliverables = [];
      member.issues = [];
    });

    return this.groupMembers;
  }

  storeGroupConfiguration(groupConfiguration) {
    this.groupConfiguration = groupConfiguration;
    return groupConfiguration;
  }

  storeMilestones(milestones) {
    const transformedMilestones = [];

    milestones.forEach((milestone) => {
      const newMilestone = milestone;
      if (newMilestone.due_date) newMilestone.due_date = new Date(newMilestone.due_date);
      if (newMilestone.start_date) newMilestone.start_date = new Date(newMilestone.start_date);
      transformedMilestones.push(newMilestone);
    });

    this.milestones = transformedMilestones;
    return milestones;
  }

  storeMilestoneDeliverables(issues) {
    this.nonAssignedMilestoneDeliverables = [];

    let doneDeliverables = 0;

    issues.forEach((issue) => {
      let foundGroupMember = false;
      issue.assignees.forEach((assignee) => {
        const selectedMember = this.groupMembers.find(member => member.id === assignee.id);
        if (selectedMember) {
          selectedMember.deliverables.push(issue);
          foundGroupMember = true;
        }
      });
      if (!foundGroupMember) {
        this.nonAssignedMilestoneDeliverables.push(issue);
      }
      if (issue.state === 'closed') {
        doneDeliverables += 1;
      }
    });

    this.milestoneDeliverables = issues;

    this.deliverableInfo.doneDeliverables = doneDeliverables;

    return issues;
  }

}
