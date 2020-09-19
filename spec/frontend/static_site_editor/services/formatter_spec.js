import formatter from '~/static_site_editor/services/formatter';

describe('static_site_editor/services/formatter', () => {
  const source = `Some text
<br>

And some more text


<br>


And even more text`;
  const sourceWithoutBrTags = `Some text

And some more text




And even more text`;

  it('removes extraneous <br> tags', () => {
    expect(formatter(source)).toMatch(sourceWithoutBrTags);
  });

  describe('ordered lists with incorrect content indentation', () => {
    it.each`
      input                                                   | result
      ${'12. ordered list item\n13.Next ordered list item'}   | ${'12. ordered list item\n13.Next ordered list item'}
      ${'12. ordered list item\n - Next ordered list item'}   | ${'12. ordered list item\n    - Next ordered list item'}
      ${'12. ordered list item\n   - Next ordered list item'} | ${'12. ordered list item\n    - Next ordered list item'}
      ${'12. ordered list item\n   Next ordered list item'}   | ${'12. ordered list item\n    Next ordered list item'}
      ${'1. ordered list item\n   Next ordered list item'}    | ${'1. ordered list item\n    Next ordered list item'}
    `('\ntransforms\n$input \nto\n$result', ({ input, result }) => {
      expect(formatter(input)).toBe(result);
    });
  });
});
