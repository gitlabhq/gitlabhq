
/* eslint-disable no-new */
import initIssuableSidebar from '~/init_issuable_sidebar';
import Issue from '~/issuable_index';
import ShortcutsIssuable from '~/shortcuts_issuable';
import ZenMode from '~/zen_mode';

export default () => {
  new Issue();
  new ShortcutsIssuable();
  new ZenMode();
  initIssuableSidebar();
};
