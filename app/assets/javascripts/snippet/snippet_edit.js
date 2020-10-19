import ZenMode from '~/zen_mode';
import SnippetsEdit from '~/snippets/components/edit.vue';
import SnippetsAppFactory from '~/snippets';

SnippetsAppFactory(document.getElementById('js-snippet-edit'), SnippetsEdit);
new ZenMode(); // eslint-disable-line no-new
