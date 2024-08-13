import { serialize, builders } from '../../serialization_utils';

const { paragraph, descriptionList, descriptionItem, heading, italic } = builders;

it('correctly renders a description list', () => {
  expect(
    serialize(
      descriptionList(
        descriptionItem(paragraph('Beast of Bodmin')),
        descriptionItem({ isTerm: false }, paragraph('A large feline inhabiting Bodmin Moor.')),

        descriptionItem(paragraph('Morgawr')),
        descriptionItem({ isTerm: false }, paragraph('A sea serpent.')),

        descriptionItem(paragraph('Owlman')),
        descriptionItem({ isTerm: false }, paragraph('A giant ', italic('owl-like'), ' creature.')),
      ),
      heading('this is a heading'),
    ),
  ).toBe(
    `
<dl>
<dt>Beast of Bodmin</dt>
<dd>A large feline inhabiting Bodmin Moor.</dd>
<dt>Morgawr</dt>
<dd>A sea serpent.</dd>
<dt>Owlman</dt>
<dd>

A giant _owl-like_ creature.

</dd>
</dl>

# this is a heading
      `.trim(),
  );
});
