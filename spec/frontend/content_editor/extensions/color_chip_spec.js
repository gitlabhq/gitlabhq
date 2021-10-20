import ColorChip, { colorDecoratorPlugin } from '~/content_editor/extensions/color_chip';
import Code from '~/content_editor/extensions/code';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/color_chip', () => {
  let tiptapEditor;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [ColorChip, Code] });
  });

  describe.each`
    colorExpression       | decorated
    ${'#F00'}             | ${true}
    ${'rgba(0,0,0,0)'}    | ${true}
    ${'hsl(540,70%,50%)'} | ${true}
    ${'F00'}              | ${false}
    ${'F00'}              | ${false}
    ${'gba(0,0,0,0)'}     | ${false}
    ${'hls(540,70%,50%)'} | ${false}
    ${'red'}              | ${false}
  `(
    'when a code span with $colorExpression color expression is found',
    ({ colorExpression, decorated }) => {
      it(`${decorated ? 'adds' : 'does not add'} a color chip decorator`, () => {
        tiptapEditor.commands.setContent(`<p><code>${colorExpression}</code></p>`);
        const pluginState = colorDecoratorPlugin.getState(tiptapEditor.state);

        expect(pluginState.children).toHaveLength(decorated ? 3 : 0);
      });
    },
  );
});
