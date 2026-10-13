import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Panel from './panel.vue';

export default () => {
  const element = document.querySelector('#js-google-cloud-databases');
  const {
    configurationUrl,
    deploymentsUrl,
    databasesUrl,
    cloudsqlPostgresUrl,
    cloudsqlMysqlUrl,
    cloudsqlSqlserverUrl,
    cloudsqlInstances,
    emptyIllustrationUrl,
  } = JSON.parse(element.getAttribute('data'));

  return initVueApp({
    el: element,
    name: 'GoogleCloudDatabasesPanelRoot',
    component: Panel,
    props: {
      configurationUrl,
      deploymentsUrl,
      databasesUrl,
      cloudsqlPostgresUrl,
      cloudsqlMysqlUrl,
      cloudsqlSqlserverUrl,
      cloudsqlInstances,
      emptyIllustrationUrl,
    },
  });
};
