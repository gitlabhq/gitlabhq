import { serialize, builders, tiptapEditor } from '../../serialization_utils';

const { paragraph } = builders;
const text = (val) => tiptapEditor.state.schema.text(val);

it('escapes < and > in a paragraph', () => {
  expect(
    serialize(paragraph(text("some prose: <this> and </this> looks like code, but isn't"))),
  ).toBe("some prose: \\<this\\> and \\</this\\> looks like code, but isn't");
});
