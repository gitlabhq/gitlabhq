import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import MlCandidateShow from '~/ml/experiment_tracking/routes/candidates/show';

initSimpleApp('#js-show-ml-candidate', MlCandidateShow, { name: 'MlCandidateShow' });
