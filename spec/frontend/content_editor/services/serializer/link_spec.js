import { serialize, builders } from '../../serialization_utils';

const { paragraph, link } = builders;

it('correctly serializes a link', () => {
  expect(serialize(paragraph(link({ href: 'https://example.com' }, 'example url')))).toBe(
    '[example url](https://example.com)',
  );
});

it('correctly serializes a plain URL link', () => {
  expect(serialize(paragraph(link({ href: 'https://example.com' }, 'https://example.com')))).toBe(
    'https://example.com',
  );
});

it('correctly escapes URLs in links', () => {
  // no double slashes
  expect(serialize(paragraph(link({ href: 'gitlab\\' }, 'link')))).toBe('[link](gitlab\\)');

  expect(serialize(paragraph(link({ href: 'foo):' }, 'link')))).toBe('[link](foo\\):)');
  expect(serialize(paragraph(link({ href: '(foo' }, 'link')))).toBe('[link](\\(foo)');
  expect(serialize(paragraph(link({ title: 'bar', href: 'foo%20"' }, 'link')))).toBe(
    '[link](foo%20\\" "bar")',
  );
});

it('does not escape backslashes or other Markdown-sensitive characters in autolinks', () => {
  expect(
    serialize(paragraph(link({ href: 'https://google.com\\a' }, 'https://google.com\\a'))),
  ).toBe('https://google.com\\a');

  expect(
    serialize(paragraph(link({ href: 'https://example.com/~foo' }, 'https://example.com/~foo'))),
  ).toBe('https://example.com/~foo');
});

it('correctly serializes a malformed URL-encoded link', () => {
  expect(
    serialize(
      paragraph(link({ href: 'https://example.com/%E0%A4%A' }, 'https://example.com/%E0%A4%A')),
    ),
  ).toBe('https://example.com/%E0%A4%A');
});

it('correctly serializes a link with a title', () => {
  expect(
    serialize(
      paragraph(link({ href: 'https://example.com', title: 'click this link' }, 'example url')),
    ),
  ).toBe('[example url](https://example.com "click this link")');
});

it('correctly serializes a plain URL link with a title', () => {
  expect(
    serialize(
      paragraph(link({ href: 'https://example.com', title: 'link title' }, 'https://example.com')),
    ),
  ).toBe('[https://example.com](https://example.com "link title")');
});

it('correctly serializes a link with a canonicalSrc', () => {
  expect(
    serialize(
      paragraph(
        link(
          {
            href: '/uploads/abcde/file.zip',
            canonicalSrc: 'file.zip',
            title: 'click here to download',
          },
          'download file',
        ),
      ),
    ),
  ).toBe('[download file](file.zip "click here to download")');
});

it('correctly serializes link references', () => {
  expect(
    serialize(
      paragraph(
        link(
          {
            href: 'gitlab-url',
            isReference: true,
          },
          'GitLab',
        ),
      ),
    ),
  ).toBe('[GitLab][gitlab-url]');
});

it.each`
  title          | canonicalSrc        | serialized
  ${'Usage'}     | ${'usage'}          | ${'[[Usage]]'}
  ${'Changelog'} | ${'docs/changelog'} | ${'[[Changelog|docs/changelog]]'}
`(
  'correctly serializes a gollum (wiki) link: $serialized',
  ({ title, canonicalSrc, serialized }) => {
    expect(
      serialize(
        paragraph(
          link(
            {
              isGollumLink: true,
              isWikiPage: true,
              href: '/gitlab-org/gitlab-test/-/wikis/link/to/some/wiki/page',
              canonicalSrc,
            },
            title,
          ),
        ),
      ),
    ).toBe(serialized);
  },
);

describe('when a link sits inside other marks', () => {
  const {
    bold,
    italic,
    strike,
    code,
    bulletList,
    listItem,
    table,
    tableRow,
    tableHeader,
    tableCell,
  } = builders;
  const href = 'https://docs.gitlab.com';
  const boldLink = () => bold('see ', link({ href }, 'docs'), ' now');

  it.each`
    marks                                     | content                                                                                                      | markdown
    ${'bold'}                                 | ${bold('see ', link({ href }, 'docs'), ' now')}                                                              | ${'**see [docs](https://docs.gitlab.com) now**'}
    ${'italic'}                               | ${italic('read the ', link({ href }, 'guide'), ' first')}                                                    | ${'_read the [guide](https://docs.gitlab.com) first_'}
    ${'bold and italic'}                      | ${bold(italic('see ', link({ href }, 'docs'), ' now'))}                                                      | ${'**_see [docs](https://docs.gitlab.com) now_**'}
    ${'strikethrough'}                        | ${strike('old ', link({ href }, 'link'), ' text')}                                                           | ${'~~old [link](https://docs.gitlab.com) text~~'}
    ${'bold with the link at the end'}        | ${bold('see ', link({ href }, 'docs'))}                                                                      | ${'**see [docs](https://docs.gitlab.com)**'}
    ${'bold with two links'}                  | ${bold('see ', link({ href }, 'docs'), ' and ', link({ href: 'https://about.gitlab.com' }, 'more'), ' now')} | ${'**see [docs](https://docs.gitlab.com) and [more](https://about.gitlab.com) now**'}
    ${'bold with inline code after the link'} | ${bold('see ', link({ href }, 'docs'), ' ', code('code'), ' now')}                                           | ${'**see [docs](https://docs.gitlab.com) `code` now**'}
    ${'bold with an autolink'}                | ${bold('see ', link({ href: 'https://gitlab.com' }, 'https://gitlab.com'), ' now')}                          | ${'**see https://gitlab.com now**'}
    ${'bold with a titled link'}              | ${bold('see ', link({ href, title: 'Docs' }, 'docs'), ' now')}                                               | ${'**see [docs](https://docs.gitlab.com "Docs") now**'}
    ${'bold with marks inside the link'}      | ${bold('see ', link({ href }, italic('docs')), ' now')}                                                      | ${'**see [_docs_](https://docs.gitlab.com) now**'}
  `('keeps $marks wrapping a link as one span', ({ content, markdown }) => {
    expect(serialize(paragraph(content))).toBe(markdown);
  });

  it.each`
    marks              | content                                   | markdown
    ${'bold'}          | ${bold('see ', link({ href }, 'docs'))}   | ${'**see [docs](https://docs.gitlab.com)**&#105;fy'}
    ${'italic'}        | ${italic('see ', link({ href }, 'docs'))} | ${'_see [docs](https://docs.gitlab.com)_&#105;fy'}
    ${'strikethrough'} | ${strike('see ', link({ href }, 'docs'))} | ${'~~see [docs](https://docs.gitlab.com)~~&#105;fy'}
  `('keeps $marks that ends at a link renderable before a letter', ({ content, markdown }) => {
    expect(serialize(paragraph(content, 'ify'))).toBe(markdown);
  });

  it('keeps marks inside a link inside the link', () => {
    expect(serialize(paragraph(link({ href }, bold('docs'))))).toBe(
      '[**docs**](https://docs.gitlab.com)',
    );
  });

  it('serializes a bold span that begins with a link with the link outermost', () => {
    expect(serialize(paragraph(bold(link({ href }, 'docs'), ' now')))).toBe(
      '[**docs**](https://docs.gitlab.com) **now**',
    );
  });

  it('keeps a bold link inside list items', () => {
    expect(
      serialize(
        bulletList(
          listItem(paragraph('first item')),
          listItem(paragraph(boldLink()), bulletList(listItem(paragraph('nested ', boldLink())))),
        ),
      ),
    ).toBe(
      `
* first item
* **see [docs](https://docs.gitlab.com) now**
  * nested **see [docs](https://docs.gitlab.com) now**
      `.trim(),
    );
  });

  it('keeps a bold link inside a table cell', () => {
    expect(
      serialize(
        table(
          tableRow(tableHeader(paragraph('Column')), tableHeader(paragraph('Note'))),
          tableRow(tableCell(paragraph('a')), tableCell(paragraph(boldLink()))),
        ),
      ).trim(),
    ).toBe(
      `
| Column | Note |
|--------|------|
| a | **see [docs](https://docs.gitlab.com) now** |
      `.trim(),
    );
  });
});
