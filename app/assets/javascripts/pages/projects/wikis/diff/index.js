import syntaxHighlight from '~/syntax_highlight';
import { initDiffStatsDropdown } from '~/init_diff_stats_dropdown';
import Diff from '~/diff';
import { mountLegacyToggleButton } from '~/wikis/mount_legacy_toggle';

new Diff(); // eslint-disable-line no-new
initDiffStatsDropdown();
syntaxHighlight([document.querySelector('.files')]);
mountLegacyToggleButton();
