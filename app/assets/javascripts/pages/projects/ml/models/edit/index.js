import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { EditMlModel } from '~/ml/model_registry/apps';

initSimpleApp('#js-mount-edit-ml-model', EditMlModel, {
  withApolloProvider: true,
  name: 'EditMlModel',
});
