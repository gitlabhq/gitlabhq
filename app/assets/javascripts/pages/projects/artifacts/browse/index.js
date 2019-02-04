import BuildArtifacts from '~/build_artifacts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';

document.addEventListener('DOMContentLoaded', () => {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new BuildArtifacts(); // eslint-disable-line no-new
});
