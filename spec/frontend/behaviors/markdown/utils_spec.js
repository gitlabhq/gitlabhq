import { toggleCheckbox } from '~/behaviors/markdown/utils';

describe('toggleCheckbox', () => {
  const rawMarkdown = `- [x] todo 1\n- [ ] todo 2`;

  it.each`
    assertionName | sourcepos     | checkboxChecked | oldLine           | newMarkdown
    ${'marks'}    | ${'2:1-2:12'} | ${true}         | ${'- [ ] todo 2'} | ${'- [x] todo 1\n- [x] todo 2'}
    ${'unmarks'}  | ${'1:1-1:12'} | ${false}        | ${'- [x] todo 1'} | ${'- [ ] todo 1\n- [ ] todo 2'}
  `(
    '$assertionName the checkbox at correct position',
    ({ sourcepos, checkboxChecked, oldLine, newMarkdown }) => {
      const result = toggleCheckbox({ rawMarkdown, sourcepos, checkboxChecked });
      expect(result.oldLine).toEqual(oldLine);
      expect(result.newMarkdown).toEqual(newMarkdown);
    },
  );

  const createInputInLi = ({ addCheckboxSourcepos }) => {
    const li = document.createElement('li');
    li.dataset.sourcepos = '2:1-2:12';

    const target = document.createElement('input');
    li.appendChild(target);
    if (addCheckboxSourcepos) {
      target.dataset.checkboxSourcepos = '2:4-2:4';
    }

    return target;
  };

  it('prefers sourcepos from data-checkbox-sourcepos when present', () => {
    const target = createInputInLi({ addCheckboxSourcepos: true });
    const result = toggleCheckbox({ rawMarkdown, checkboxChecked: true, target });
    expect(result.oldLine).toEqual('- [ ] todo 2');
    expect(result.newMarkdown).toEqual('- [x] todo 1\n- [x] todo 2');
    expect(result.sourcepos).toEqual('2:4-2:4');
  });

  it("obtains sourcepos from parent's data-sourcepos when data-checkbox-sourcepos isn't present", () => {
    const target = createInputInLi({ addCheckboxSourcepos: false });
    const result = toggleCheckbox({ rawMarkdown, checkboxChecked: true, target });
    expect(result.oldLine).toEqual('- [ ] todo 2');
    expect(result.newMarkdown).toEqual('- [x] todo 1\n- [x] todo 2');
    expect(result.sourcepos).toEqual('2:1-2:12');
  });
});
