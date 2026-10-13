import initTree from 'ee_else_ce/repository';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initAmbiguousRefModal from '~/vue_shared/components/ref/init_ambiguous_ref_modal';

initTree();
initAmbiguousRefModal();
addShortcutsExtension(ShortcutsNavigation);
