import Vue from 'vue';
import VueRouter from 'vue-router';
import { initSimpleApp } from '~/helpers/init_simple_app_helper';
import { ShowMlModel } from '~/ml/model_registry/apps';

Vue.use(VueRouter);

initSimpleApp('#js-mount-show-ml-model', ShowMlModel, {
  withApolloProvider: true,
  name: 'ShowMlModel',
});
