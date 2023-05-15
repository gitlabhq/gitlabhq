import syntaxHighlight from '~/syntax_highlight';
import { initDiffStatsDropdown } from '~/init_diff_stats_dropdown';
import Diff from '~/diff';

new Diff(); // eslint-disable-line no-new
initDiffStatsDropdown();
syntaxHighlight([document.querySelector('.files')]);
