import Vue from 'vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Translate from '~/vue_shared/translate';
import BackgroundMigrationsDatabaseListbox from './components/database_listbox.vue';

Vue.use(Translate);

export const initBackgroundMigrationsApp = () => {
  const el = document.getElementById('js-database-listbox');

  if (!el) {
    return false;
  }

  const { selectedDatabase } = el.dataset;
  let { databases } = el.dataset;

  try {
    databases = JSON.parse(databases).map((database) => ({
      value: database,
      text: database,
    }));
  } catch (e) {
    Sentry.captureException(e);
  }

  return initVueApp({
    el,
    name: 'BackgroundMigrationsDatabaseListboxRoot',
    component: BackgroundMigrationsDatabaseListbox,
    props: {
      databases,
      selectedDatabase,
    },
  });
};
