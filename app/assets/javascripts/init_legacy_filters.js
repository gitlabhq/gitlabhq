/* eslint-disable no-new */
import LabelsSelect from './labels_select';
/* global MilestoneSelect */
import subscriptionSelect from './subscription_select';
import UsersSelect from './users_select';
import issueStatusSelect from './issue_status_select';

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  issueStatusSelect();
  subscriptionSelect();
};
