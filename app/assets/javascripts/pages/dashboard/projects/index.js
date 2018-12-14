import ProjectsList from '~/projects_list';
import Star from '../../../star';

document.addEventListener('DOMContentLoaded', () => {
  new ProjectsList(); // eslint-disable-line no-new
  new Star('.project-row'); // eslint-disable-line no-new
});
