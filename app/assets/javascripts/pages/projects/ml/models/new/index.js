import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { NewMlModel } from '~/ml/model_registry/apps';

initSimpleApp('#js-mount-new-ml-model', NewMlModel, {
  withApolloProvider: true,
  name: 'NewMlModel',
});
