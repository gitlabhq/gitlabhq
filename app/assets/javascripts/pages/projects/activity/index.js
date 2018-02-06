import Activities from '~/activities';
import ShortcutsNavigation from '~/shortcuts_navigation';

export default function () {
  new Activities(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
}
