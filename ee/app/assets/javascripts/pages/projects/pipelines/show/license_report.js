import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import LicenseReportApp from 'ee/vue_shared/license_management/mr_widget_license_report.vue';
import { convertPermissionToBoolean } from '~/lib/utils/common_utils';
import { updateBadgeCount } from './utils';

Vue.use(Translate);

export default () => {
  const licensesTab = document.getElementById('js-licenses-app');

  if (licensesTab) {
    const { licenseHeadPath, canManageLicenses, apiUrl } = licensesTab.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: licensesTab,
      components: {
        LicenseReportApp,
      },
      render(createElement) {
        return createElement('license-report-app', {
          props: {
            apiUrl,
            headPath: licenseHeadPath,
            canManageLicenses: convertPermissionToBoolean(canManageLicenses),
            alwaysOpen: true,
            reportSectionClass: 'split-report-section',
          },
          on: {
            updateBadgeCount: (count) => {
              updateBadgeCount('.js-licenses-counter', count);
            },
          },
        });
      },
    });
  }
};
