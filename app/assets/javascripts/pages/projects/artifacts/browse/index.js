import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import BuildArtifacts from '~/build_artifacts';

document.addEventListener('DOMContentLoaded', () => {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new BuildArtifacts(); // eslint-disable-line no-new
});
