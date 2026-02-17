import { serialize, builders, text } from '../../serialization_utils';

const { paragraph } = builders;

it('escapes < and > in a paragraph', () => {
  expect(
    serialize(paragraph(text("some prose: <this> and </this> looks like code, but isn't"))),
  ).toBe("some prose: \\<this\\> and \\</this\\> looks like code, but isn't");
});
