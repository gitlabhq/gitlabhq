import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { NewMlModelVersion } from '~/ml/model_registry/apps';

initSimpleApp('#js-mount-new-ml-model-version', NewMlModelVersion, {
  withApolloProvider: true,
  name: 'NewMlModelVersion',
});
