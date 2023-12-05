import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import BuildArtifacts from '~/build_artifacts';

addShortcutsExtension(ShortcutsNavigation);
new BuildArtifacts(); // eslint-disable-line no-new
