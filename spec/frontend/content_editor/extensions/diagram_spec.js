import Diagram from '~/content_editor/extensions/diagram';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';

describe('content_editor/extensions/diagram', () => {
  it('inherits from code block highlight extension', () => {
    expect(Diagram.parent).toBe(CodeBlockHighlight);
  });

  it('sets isDiagram attribute to true by default', () => {
    expect(Diagram.config.addAttributes()).toEqual(
      expect.objectContaining({
        isDiagram: { default: true },
      }),
    );
  });
});
