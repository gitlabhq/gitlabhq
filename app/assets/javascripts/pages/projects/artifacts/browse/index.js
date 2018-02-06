import BuildArtifacts from '~/build_artifacts';
import ShortcutsNavigation from '~/shortcuts_navigation';

export default function () {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new BuildArtifacts(); // eslint-disable-line no-new
}
