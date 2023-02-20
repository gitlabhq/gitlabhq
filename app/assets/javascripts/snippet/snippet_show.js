import loadAwardsHandler from '~/awards_handler';
import initDeprecatedNotes from '~/init_deprecated_notes';
import SnippetsAppFactory from '~/snippets';
import SnippetsShow from '~/snippets/components/show.vue';
import ZenMode from '~/zen_mode';
import { initReportAbuse } from '~/projects/report_abuse';

SnippetsAppFactory(document.getElementById('js-snippet-view'), SnippetsShow);

initDeprecatedNotes();
loadAwardsHandler();
initReportAbuse();

// eslint-disable-next-line no-new
new ZenMode();
