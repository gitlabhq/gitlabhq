import initIssuableSidebar from '~/init_issuable_sidebar';
import Issue from '~/issue';
import ShortcutsIssuable from '~/shortcuts_issuable';
import ZenMode from '~/zen_mode';
import '~/notes/index';
import '~/issue_show/index';

export default function () {
  new Issue(); // eslint-disable-line no-new
  new ShortcutsIssuable(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
  initIssuableSidebar();
}
