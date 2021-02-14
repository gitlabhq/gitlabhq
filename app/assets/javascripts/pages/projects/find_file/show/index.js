import $ from 'jquery';
import ShortcutsFindFile from '~/behaviors/shortcuts/shortcuts_find_file';
import ProjectFindFile from '~/project_find_file';

const findElement = document.querySelector('.js-file-finder');
const projectFindFile = new ProjectFindFile($('.file-finder-holder'), {
  url: findElement.dataset.fileFindUrl,
  treeUrl: findElement.dataset.findTreeUrl,
  blobUrlTemplate: findElement.dataset.blobUrlTemplate,
});
new ShortcutsFindFile(projectFindFile); // eslint-disable-line no-new
