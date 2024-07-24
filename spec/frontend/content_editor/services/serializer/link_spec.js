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
