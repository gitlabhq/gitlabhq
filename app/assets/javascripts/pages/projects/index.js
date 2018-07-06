import gcpSignupOffer from '~/clusters/components/gcp_signup_offer';
import initGkeDropdowns from '~/projects/gke_cluster_dropdowns';
import Project from './project';
import ShortcutsNavigation from '../../shortcuts_navigation';

document.addEventListener('DOMContentLoaded', () => {
  const { page } = document.body.dataset;
  const newClusterViews = [
    'projects:clusters:new',
    'projects:clusters:create_gcp',
    'projects:clusters:create_user',
  ];

  if (newClusterViews.indexOf(page) > -1) {
    gcpSignupOffer();
    initGkeDropdowns();
  }

  new Project(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
});
