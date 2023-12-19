import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';

initSimpleApp('#js-mount-show-ml-model-version', ShowMlModelVersion, { withApolloProvider: true });
