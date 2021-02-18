import SnippetsAppFactory from '~/snippets';
import SnippetsEdit from '~/snippets/components/edit.vue';
import ZenMode from '~/zen_mode';

SnippetsAppFactory(document.getElementById('js-snippet-edit'), SnippetsEdit);
new ZenMode(); // eslint-disable-line no-new
