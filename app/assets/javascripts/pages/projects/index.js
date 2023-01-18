import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initTerraformNotification from '~/projects/terraform_notification';
import Project from './project';

new Project(); // eslint-disable-line no-new
new ShortcutsNavigation(); // eslint-disable-line no-new
initTerraformNotification();
