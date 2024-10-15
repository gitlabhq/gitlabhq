import { sidebarEntriesToTree } from '~/pages/shared/wikis/utils';

describe('sidebarEntriesToTree', () => {
  it('returns an empty array if entries are empty', () => {
    expect(sidebarEntriesToTree([])).toEqual([]);
  });

  it('returns a tree structure from sidebar entries', () => {
    const entries = [
      { slug: 'foo/bak', path: '/foo/bak', title: 'Bak' },
      { slug: 'foo', path: '/foo', title: 'Foo' },
      { slug: 'foo/bar', path: '/foo/bar', title: 'Bar' },
      { slug: 'foo/baz', path: '/foo/baz', title: 'Baz' },
      { slug: 'bar', path: '/bar', title: 'Bar' },
      { slug: 'bar/foo/baz', path: '/bar/foo/baz', title: 'Baz' },
      { slug: 'foo-bar-baz/baz', path: '/foo-bar-baz/baz', title: 'Baz' },
      { slug: 'foo/bat', path: '/foo/bat', title: 'Bat' },
      { slug: 'a/b/c/d/e/f/g', path: '/a/b/c/d/e/f/g', title: 'G' },
    ];

    expect(sidebarEntriesToTree(entries)).toMatchObject([
      {
        slug: 'a',
        path: '/a',
        title: 'a',
        children: [
          {
            slug: 'a/b',
            path: '/a/b',
            title: 'b',
            children: [
              {
                slug: 'a/b/c',
                path: '/a/b/c',
                title: 'c',
                children: [
                  {
                    slug: 'a/b/c/d',
                    path: '/a/b/c/d',
                    title: 'd',
                    children: [
                      {
                        slug: 'a/b/c/d/e',
                        path: '/a/b/c/d/e',
                        title: 'e',
                        children: [
                          {
                            slug: 'a/b/c/d/e/f',
                            path: '/a/b/c/d/e/f',
                            title: 'f',
                            children: [
                              { slug: 'a/b/c/d/e/f/g', path: '/a/b/c/d/e/f/g', title: 'G' },
                            ],
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
      {
        slug: 'bar',
        path: '/bar',
        title: 'Bar',
        children: [
          {
            slug: 'bar/foo',
            path: '/bar/foo',
            title: 'foo',
            children: [{ slug: 'bar/foo/baz', path: '/bar/foo/baz', title: 'Baz' }],
          },
        ],
      },
      {
        slug: 'foo',
        path: '/foo',
        title: 'Foo',
        children: [
          { slug: 'foo/bak', path: '/foo/bak', title: 'Bak' },
          { slug: 'foo/bar', path: '/foo/bar', title: 'Bar' },
          { slug: 'foo/bat', path: '/foo/bat', title: 'Bat' },
          { slug: 'foo/baz', path: '/foo/baz', title: 'Baz' },
        ],
      },
      {
        slug: 'foo-bar-baz',
        path: '/foo-bar-baz',
        title: 'foo bar baz',
        children: [{ slug: 'foo-bar-baz/baz', path: '/foo-bar-baz/baz', title: 'Baz' }],
      },
    ]);
  });

  it('works properly even if the slugs contain special characters and emojis', () => {
    const entries = [
      { path: '/00-START-HERE-:-)', slug: '00-START-HERE-:-)', title: '00 START HERE : )' },
      {
        path: '/Page-that-should-break-the-sidebar-)',
        slug: 'Page-that-should-break-the-sidebar-)',
        title: 'Page that should break the sidebar )',
      },
      {
        path: '/What-about-this-/-new-subpage',
        slug: 'What-about-this-/-new-subpage',
        title: 'these subpages seems working just fine',
      },
      {
        path: '/What-about-utf-%F0%9F%A4%AC',
        slug: 'What-about-utf-🤬',
        title: 'What about utf 🤬',
      },
      { path: '/home', slug: 'home', title: 'Home' },
      { path: '/-not-trimmed-', slug: '-not-trimmed-', title: ' Not trimmed ' },
    ];

    expect(sidebarEntriesToTree(entries)).toMatchObject([
      { path: '/-not-trimmed-', slug: '-not-trimmed-', title: ' Not trimmed ' },
      { slug: '00-START-HERE-:-)', path: '/00-START-HERE-:-)', title: '00 START HERE : )' },
      { slug: 'home', path: '/home', title: 'Home' },
      {
        slug: 'Page-that-should-break-the-sidebar-)',
        path: '/Page-that-should-break-the-sidebar-)',
        title: 'Page that should break the sidebar )',
      },
      {
        slug: 'What-about-this-',
        path: '/What-about-this-',
        title: 'What about this ',
        children: [
          {
            slug: 'What-about-this-/-new-subpage',
            path: '/What-about-this-/-new-subpage',
            title: 'these subpages seems working just fine',
          },
        ],
      },
      {
        slug: 'What-about-utf-🤬',
        path: '/What-about-utf-%F0%9F%A4%AC',
        title: 'What about utf 🤬',
      },
    ]);
  });
});
