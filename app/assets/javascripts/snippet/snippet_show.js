if (!gon.features.snippetsVue) {
  const LineHighlighterModule = import('~/line_highlighter');
  const BlobViewerModule = import('~/blob/viewer');
  const ZenModeModule = import('~/zen_mode');
  const SnippetEmbedModule = import('~/snippet/snippet_embed');
  const initNotesModule = import('~/init_notes');
  const loadAwardsHandlerModule = import('~/awards_handler');

  Promise.all([
    LineHighlighterModule,
    BlobViewerModule,
    ZenModeModule,
    SnippetEmbedModule,
    initNotesModule,
    loadAwardsHandlerModule,
  ])
    .then(
      ([
        { default: LineHighlighter },
        { default: BlobViewer },
        { default: ZenMode },
        { default: SnippetEmbed },
        { default: initNotes },
        { default: loadAwardsHandler },
      ]) => {
        new LineHighlighter(); // eslint-disable-line no-new
        new BlobViewer(); // eslint-disable-line no-new
        new ZenMode(); // eslint-disable-line no-new
        SnippetEmbed();
        initNotes();
        loadAwardsHandler();
      },
    )
    .catch(() => {});
} else {
  import('~/snippets')
    .then(({ SnippetShowInit }) => {
      SnippetShowInit();
    })
    .then(() => {
      return Promise.all([import('~/init_notes'), import('~/awards_handler')]);
    })
    .then(([{ default: initNotes }, { default: loadAwardsHandler }]) => {
      initNotes();
      loadAwardsHandler();
    })
    .catch(() => {});
}
