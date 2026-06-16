import initTree from 'ee_else_ce/repository';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initFindFileShortcut } from '~/projects/behaviors';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

if (gon.features?.vue3MigrateRepository) {
  (async () => {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { default: initTree } = await import('ee_else_ce/repository?vue3');
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { default: initAmbiguousRefModal } = await import(
        '~/ref/init_ambiguous_ref_modal?vue3'
      );
      initTree();
      initAmbiguousRefModal();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }

    initTree();
    initAmbiguousRefModal();
  })();
} else {
  initTree();
  initAmbiguousRefModal();
}
addShortcutsExtension(ShortcutsNavigation);
initFindFileShortcut();
