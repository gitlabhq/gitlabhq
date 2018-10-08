import '~/pages/projects/new/index';
import initCustomProjectTemplates from 'ee/projects/custom_project_templates';
import bindTrackEvents from 'ee/projects/track_project_new';

document.addEventListener('DOMContentLoaded', () => {
  initCustomProjectTemplates();
  bindTrackEvents('.js-toggle-container');
});
