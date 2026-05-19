import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsFindFile from '~/behaviors/shortcuts/shortcuts_find_file';
import ProjectFindFile from '~/projects/project_find_file';
import { initFindFileRefSwitcher } from './init_find_file_ref_switcher';

initFindFileRefSwitcher();
const findElement = document.querySelector('.js-file-finder');
const projectFindFile = new ProjectFindFile(document.querySelector('.file-finder-holder'), {
  treeUrl: findElement.dataset.findTreeUrl,
  blobUrlTemplate: findElement.dataset.blobUrlTemplate,
  refType: findElement.dataset.refType,
});
projectFindFile.load(findElement.dataset.fileFindUrl);
addShortcutsExtension(ShortcutsFindFile, projectFindFile);
