import initNotes from '~/init_notes';
import loadAwardsHandler from '~/awards_handler';
import SnippetsShow from '~/snippets/components/show.vue';
import SnippetsAppFactory from '~/snippets';
import ZenMode from '~/zen_mode';

SnippetsAppFactory(document.getElementById('js-snippet-view'), SnippetsShow);

initNotes();
loadAwardsHandler();

// eslint-disable-next-line no-new
new ZenMode();
