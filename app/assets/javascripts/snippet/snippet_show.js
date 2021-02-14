import loadAwardsHandler from '~/awards_handler';
import initNotes from '~/init_notes';
import SnippetsAppFactory from '~/snippets';
import SnippetsShow from '~/snippets/components/show.vue';
import ZenMode from '~/zen_mode';

SnippetsAppFactory(document.getElementById('js-snippet-view'), SnippetsShow);

initNotes();
loadAwardsHandler();

// eslint-disable-next-line no-new
new ZenMode();
