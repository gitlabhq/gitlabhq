import Vue from 'vue';
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

  return new Vue({
    el,
    render(createElement) {
      return createElement(BackgroundMigrationsDatabaseListbox, {
        props: {
          databases,
          selectedDatabase,
        },
      });
    },
  });
};
