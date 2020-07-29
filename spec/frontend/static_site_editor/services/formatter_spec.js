import formatter from '~/static_site_editor/services/formatter';

describe('formatter', () => {
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
});
