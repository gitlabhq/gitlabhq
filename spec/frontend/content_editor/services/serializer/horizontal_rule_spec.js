import { serialize, builders } from '../../serialization_utils';

const { horizontalRule } = builders;

it('correctly serializes horizontal rule', () => {
  expect(serialize(horizontalRule(), horizontalRule(), horizontalRule())).toBe(
    `
---

---

---
      `.trim(),
  );
});
