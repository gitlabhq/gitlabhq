import initNotes from '~/init_notes';
import loadAwardsHandler from '~/awards_handler';

if (!gon.features.snippetsVue) {
  const LineHighlighterModule = import('~/line_highlighter');
  const BlobViewerModule = import('~/blob/viewer');
  const ZenModeModule = import('~/zen_mode');
  const SnippetEmbedModule = import('~/snippet/snippet_embed');

  Promise.all([LineHighlighterModule, BlobViewerModule, ZenModeModule, SnippetEmbedModule])
    .then(
      ([
        { default: LineHighlighter },
        { default: BlobViewer },
        { default: ZenMode },
        { default: SnippetEmbed },
      ]) => {
        new LineHighlighter(); // eslint-disable-line no-new
        new BlobViewer(); // eslint-disable-line no-new
        new ZenMode(); // eslint-disable-line no-new
        SnippetEmbed();
      },
    )
    .catch(() => {});
} else {
  import('~/snippets')
    .then(({ SnippetShowInit }) => {
      SnippetShowInit();
    })
    .catch(() => {});
}
initNotes();
loadAwardsHandler();
