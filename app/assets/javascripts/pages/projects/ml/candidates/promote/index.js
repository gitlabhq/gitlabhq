import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import PromoteRun from '~/ml/experiment_tracking/routes/candidates/promote/promote_run.vue';

initSimpleApp('#js-promote-ml-candidate', PromoteRun, {
  withApolloProvider: true,
  name: 'PromoteRun',
});
