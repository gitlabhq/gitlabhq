import $ from 'jquery';
import ProjectFindFile from '~/project_find_file';
import ShortcutsFindFile from '~/shortcuts_find_file';

document.addEventListener('DOMContentLoaded', () => {
  const findElement = document.querySelector('.js-file-finder');
  const projectFindFile = new ProjectFindFile($('.file-finder-holder'), {
    url: findElement.dataset.fileFindUrl,
    treeUrl: findElement.dataset.findTreeUrl,
    blobUrlTemplate: findElement.dataset.blobUrlTemplate,
  });
  new ShortcutsFindFile(projectFindFile); // eslint-disable-line no-new
});
