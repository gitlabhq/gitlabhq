import $ from 'jquery';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsFindFile from '~/behaviors/shortcuts/shortcuts_find_file';
import ProjectFindFile from '~/projects/project_find_file';
import InitBlobRefSwitcher from '../ref_switcher';

InitBlobRefSwitcher();
const findElement = document.querySelector('.js-file-finder');
const projectFindFile = new ProjectFindFile($('.file-finder-holder'), {
  treeUrl: findElement.dataset.findTreeUrl,
  blobUrlTemplate: findElement.dataset.blobUrlTemplate,
  refType: findElement.dataset.refType,
});
projectFindFile.load(findElement.dataset.fileFindUrl);
addShortcutsExtension(ShortcutsFindFile, projectFindFile);
