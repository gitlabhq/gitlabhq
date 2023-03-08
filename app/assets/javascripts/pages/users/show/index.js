import { s__ } from '~/locale';
import { createAlert } from '~/alert';

if (window.gon.features?.profileTabsVue) {
  import('~/profile')
    .then(({ initProfileTabs }) => {
      initProfileTabs();
    })
    .catch(() => {
      createAlert({
        message: s__(
          'UserProfile|An error occurred loading the profile. Please refresh the page to try again.',
        ),
      });
    });
}
