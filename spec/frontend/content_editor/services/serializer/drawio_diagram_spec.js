import { serialize, builders } from '../../serialization_utils';

const { paragraph, drawioDiagram } = builders;

it('correctly serializes a drawio_diagram', () => {
  expect(
    serialize(paragraph(drawioDiagram({ src: 'diagram.drawio.svg', alt: 'Draw.io Diagram' }))),
  ).toBe('![Draw.io Diagram](diagram.drawio.svg)');
});
