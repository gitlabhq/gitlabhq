/* eslint-disable no-new */
/* global LabelsSelect */
/* global MilestoneSelect */
/* global IssueStatusSelect */
/* global SubscriptionSelect */
/* global WeightSelect */

import UsersSelect from './users_select';

export default () => {
  new UsersSelect();
  new LabelsSelect();
  new MilestoneSelect();
  new IssueStatusSelect();
  new SubscriptionSelect();
  new WeightSelect();
};
