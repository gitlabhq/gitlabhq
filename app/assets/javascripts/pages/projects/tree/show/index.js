import initTree from 'ee_else_ce/repository';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initFindFileShortcut } from '~/projects/behaviors';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';

initTree();
initAmbiguousRefModal();
addShortcutsExtension(ShortcutsNavigation);
initFindFileShortcut();
