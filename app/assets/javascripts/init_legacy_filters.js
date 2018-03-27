/* eslint-disable no-new */
import LabelsSelect from './labels_select';
import subscriptionSelect from './subscription_select';
import UsersSelect from './users_select';
import issueStatusSelect from './issue_status_select';
import MilestoneSelect from './milestone_select';

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  issueStatusSelect();
  subscriptionSelect();
};
