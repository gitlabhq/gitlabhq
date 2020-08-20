import ProjectsList from '~/projects_list';
import initCustomizeHomepageBanner from './init_customize_homepage_banner';

document.addEventListener('DOMContentLoaded', () => {
  new ProjectsList(); // eslint-disable-line no-new

  initCustomizeHomepageBanner();
});
