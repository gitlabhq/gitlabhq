import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { EditMlModelVersion } from '~/ml/model_registry/apps';

initSimpleApp('#js-mount-edit-ml-model-version', EditMlModelVersion, {
  withApolloProvider: true,
  name: 'EditMlModelVersion',
});
