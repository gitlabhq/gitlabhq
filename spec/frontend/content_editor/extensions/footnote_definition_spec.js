import FootnoteDefinition from '~/content_editor/extensions/footnote_definition';

describe('content_editor/extensions/footnote_definition', () => {
  it('sets the isolation option to true', () => {
    expect(FootnoteDefinition.config.isolating).toBe(true);
  });
});
