import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { IndexMlModels } from '~/ml/model_registry/apps';

initSimpleApp('#js-index-ml-models', IndexMlModels, {
  withApolloProvider: true,
  name: 'IndexMlModels',
});
