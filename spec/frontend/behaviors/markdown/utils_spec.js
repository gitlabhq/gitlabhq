import { toggleMarkCheckboxes } from '~/behaviors/markdown/utils';

describe('toggleMarkCheckboxes', () => {
  const rawMarkdown = `- [x] todo 1\n- [ ] todo 2`;

  it.each`
    assertionName | sourcepos     | checkboxChecked | expectedMarkdown
    ${'marks'}    | ${'2:1-2:12'} | ${true}         | ${'- [x] todo 1\n- [x] todo 2'}
    ${'unmarks'}  | ${'1:1-1:12'} | ${false}        | ${'- [ ] todo 1\n- [ ] todo 2'}
  `(
    '$assertionName the checkbox at correct position',
    ({ sourcepos, checkboxChecked, expectedMarkdown }) => {
      expect(toggleMarkCheckboxes({ rawMarkdown, sourcepos, checkboxChecked })).toEqual(
        expectedMarkdown,
      );
    },
  );
});
