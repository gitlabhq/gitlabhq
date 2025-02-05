import Vue from 'vue';
import VueRouter from 'vue-router';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';

Vue.use(VueRouter);

initSimpleApp('#js-mount-show-ml-model-version', ShowMlModelVersion, {
  withApolloProvider: true,
  name: 'ShowMlModelVersion',
});
