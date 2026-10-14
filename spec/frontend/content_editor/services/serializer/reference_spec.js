import { serialize, builders, text, roundTrip } from '../../serialization_utils';

const { paragraph, blockquote, reference, referenceLabel, bold, italic, code, strike } = builders;

const issue = (iid) =>
  reference({
    referenceType: 'issue',
    originalText: `#${iid}`,
    href: `/gitlab-org/gitlab-test/-/issues/${iid}`,
    text: `#${iid}`,
  });

const mergeRequest = (iid) =>
  reference({
    referenceType: 'merge_request',
    originalText: `!${iid}`,
    href: `/gitlab-org/gitlab-test/-/merge_requests/${iid}`,
    text: `!${iid}`,
  });

const user = (username) =>
  reference({
    referenceType: 'user',
    originalText: `@${username}`,
    href: `/${username}`,
    text: `@${username}`,
  });

const renderedReference = (type, original, href) =>
  `<a href="${href}" class="gfm gfm-${type}" data-original="${original}" data-link="false" data-link-reference="false" data-reference-type="${type}">${original}</a>`;

it('correctly serializes references', () => {
  expect(
    serialize(
      paragraph(
        reference({
          referenceType: 'issue',
          originalText: '#123',
          href: '/gitlab-org/gitlab-test/-/issues/123',
          text: '#123',
        }),
      ),
    ),
  ).toBe('#123');
});

it('ensures spaces between multiple references', () => {
  expect(
    serialize(
      paragraph(
        reference({
          referenceType: 'issue',
          originalText: '#123',
          href: '/gitlab-org/gitlab-test/-/issues/123',
          text: '#123',
        }),
        referenceLabel({
          referenceType: 'label',
          originalText: '~foo',
          href: '/gitlab-org/gitlab-test/-/labels/foo',
          text: '~foo',
        }),
        reference({
          referenceType: 'issue',
          originalText: '#456',
          href: '/gitlab-org/gitlab-test/-/issues/456',
          text: '#456',
        }),
      ),
      paragraph(
        reference({
          referenceType: 'command',
          originalText: '/assign_reviewer',
          text: '/assign_reviewer',
        }),
        reference({
          referenceType: 'user',
          originalText: '@johndoe',
          href: '/johndoe',
          text: '@johndoe',
        }),
      ),
    ),
  ).toBe('#123 ~foo #456\n\n/assign_reviewer @johndoe');
});

it('does not add extra spaces in parenthesis, braces or square brackets', () => {
  expect(
    serialize(
      paragraph(
        text('('),
        reference({
          referenceType: 'issue',
          originalText: '#123',
          href: '/gitlab-org/gitlab-test/-/issues/123',
          text: '#123',
        }),
        text(') '),
        text('['),
        reference({
          referenceType: 'label',
          originalText: '~foo',
          href: '/gitlab-org/gitlab-test/-/labels/foo',
          text: '~foo',
        }),
        text('] '),
        text('{'),
        reference({
          referenceType: 'issue',
          originalText: '#456',
          href: '/gitlab-org/gitlab-test/-/issues/456',
          text: '#456',
        }),
        text('}'),
      ),
    ),
    // Square brackets are escaped since they have special meaning in Markdown
  ).toBe('(#123) \\[~foo\\] {#456}');
});

it('does not add extra spaces in quotes (single, double and backticks)', () => {
  expect(
    serialize(
      paragraph(
        text('"'),
        reference({
          referenceType: 'issue',
          originalText: '#123',
          href: '/gitlab-org/gitlab-test/-/issues/123',
          text: '#123',
        }),
        text('" '),
        text('`'),
        referenceLabel({
          referenceType: 'label',
          originalText: '~foo',
          href: '/gitlab-org/gitlab-test/-/labels/foo',
          text: '~foo',
        }),
        text('` '),
        text("'"),
        reference({
          referenceType: 'issue',
          originalText: '#456',
          href: '/gitlab-org/gitlab-test/-/issues/456',
          text: '#456',
        }),
        text("'"),
      ),
    ),
  ).toBe('"#123" \\`~foo\\` \'#456\'');
});

it('does not add additional spaces when references are the only thing contained in a mark (like bold, code, italic, strike)', () => {
  expect(
    serialize(
      paragraph(
        bold(
          reference({
            referenceType: 'issue',
            originalText: '#123',
            href: '/gitlab-org/gitlab-test/-/issues/123',
            text: '#123',
          }),
        ),
        text(' '),
        code(
          referenceLabel({
            referenceType: 'label',
            originalText: '~foo',
            href: '/gitlab-org/gitlab-test/-/labels/foo',
            text: '~foo',
          }),
        ),
        text(' '),
        italic(
          reference({
            referenceType: 'issue',
            originalText: '#456',
            href: '/gitlab-org/gitlab-test/-/issues/456',
            text: '#456',
          }),
        ),
        text(' '),
        strike(
          reference({
            referenceType: 'epic',
            originalText: '&4',
            href: '/groups/gitlab-org/-/epics/4',
            text: '&4',
          }),
        ),
      ),
    ),
  ).toBe('**#123** `~foo` _#456_ ~~&4~~');
});

it.each`
  description                | content                                                                                      | expected
  ${'a slash'}               | ${[issue(1), text('/'), issue(2)]}                                                           | ${'#1/#2'}
  ${'a hyphen'}              | ${[issue(1), text('-'), issue(2)]}                                                           | ${'#1-#2'}
  ${'a slash between users'} | ${[user('root'), text('/'), user('user')]}                                                   | ${'@root/@user'}
  ${'commas and full stops'} | ${[text('see '), issue(1), text('/'), issue(2), text(', and '), mergeRequest(1), text('.')]} | ${'see #1/#2, and !1.'}
`('does not add a space between references and $description', ({ content, expected }) => {
  expect(serialize(paragraph(...content))).toBe(expected);
});

it('adds a space between a reference and a preceding letter, digit or literal underscore', () => {
  expect(
    serialize(
      paragraph(text('issue'), issue(1), text(' or 2'), issue(2), text(' or snake_'), issue(3)),
    ),
  ).toBe('issue #1 or 2 #2 or snake\\_ #3');
});

const label = (name) =>
  referenceLabel({
    referenceType: 'label',
    originalText: `~${name}`,
    href: `/gitlab-org/gitlab-test/-/labels/${name}`,
    text: `~${name}`,
  });

const quotedLabel = (name) =>
  referenceLabel({
    referenceType: 'label',
    originalText: `~"${name}"`,
    href: `/gitlab-org/gitlab-test/-/labels/${name}`,
    text: name,
  });

const milestone = (title) =>
  reference({
    referenceType: 'milestone',
    originalText: `%${title}`,
    href: `/gitlab-org/gitlab-test/-/milestones/1`,
    text: `%${title}`,
  });

it.each`
  description                                  | content                                    | expected
  ${'word ending in a hyphen'}                 | ${[text('foo-'), issue(1)]}                | ${'foo- #1'}
  ${'version ending in a dot'}                 | ${[text('v1.'), issue(1)]}                 | ${'v1. #1'}
  ${'hyphenated word'}                         | ${[text('x-y-'), issue(1)]}                | ${'x-y- #1'}
  ${'dotted name'}                             | ${[text('a.b'), issue(1)]}                 | ${'a.b #1'}
  ${'hyphenated word after another reference'} | ${[issue(1), text(' and x-y-'), issue(2)]} | ${'#1 and x-y- #2'}
`('adds a space between a reference and a preceding $description', ({ content, expected }) => {
  expect(serialize(paragraph(...content))).toBe(expected);
});

it('adds a space between a reference and a preceding hyphenated word after a multiline blockquote that ends with a reference', () => {
  expect(
    serialize(
      blockquote({ multiline: true }, paragraph(issue(1))),
      paragraph(text('foo-'), issue(2)),
    ),
  ).toBe('>>>\n#1\n\n>>>\n\nfoo- #2');
});

it.each`
  description                                            | content                                     | expected
  ${'letter after an issue'}                             | ${[issue(1), text('abc')]}                  | ${'#1 abc'}
  ${'digit after a merge request'}                       | ${[mergeRequest(1), text('2nd')]}           | ${'!1 2nd'}
  ${'letter after a label'}                              | ${[label('bug'), text('x')]}                | ${'~bug x'}
  ${'hyphen and a reference after a label'}              | ${[label('bug'), text('-'), issue(1)]}      | ${'~bug -#1'}
  ${'dotted word after a user'}                          | ${[user('root'), text('.x')]}               | ${'@root .x'}
  ${'letter after an unquoted milestone'}                | ${[milestone('17.5'), text('x')]}           | ${'%17.5 x'}
  ${'question mark and a letter'}                        | ${[label('bug'), text('?x')]}               | ${'~bug ?x'}
  ${'ampersand after a label'}                           | ${[label('bug'), text('& more')]}           | ${'~bug & more'}
  ${'slash and a reference after an unquoted milestone'} | ${[milestone('17.5'), text('/'), issue(2)]} | ${'%17.5 /#2'}
  ${'slash and a letter after an unquoted milestone'}    | ${[milestone('17.5'), text('/x')]}          | ${'%17.5 /x'}
  ${'slash and a letter after a user'}                   | ${[user('root'), text('/x')]}               | ${'@root /x'}
  ${'colon and a letter after a label'}                  | ${[label('bug'), text(':x')]}               | ${'~bug :x'}
`('adds a space between a reference and a following $description', ({ content, expected }) => {
  expect(serialize(paragraph(...content))).toBe(expected);
});

it.each`
  description                                    | content                                             | expected
  ${'a full stop ending the sentence'}           | ${[text('Thanks '), user('root'), text('. Next')]}  | ${'Thanks @root. Next'}
  ${'a question mark ending the paragraph'}      | ${[text('Is it '), label('bug'), text('?')]}        | ${'Is it ~bug?'}
  ${'a full stop after an unquoted milestone'}   | ${[text('In '), milestone('17.5'), text('. Next')]} | ${'In %17.5. Next'}
  ${'a question mark and a letter after a user'} | ${[user('root'), text('?x')]}                       | ${'@root?x'}
  ${'an ampersand after an unquoted milestone'}  | ${[milestone('17.5'), text('& more')]}              | ${'%17.5& more'}
`('does not add a space between a named reference and $description', ({ content, expected }) => {
  expect(serialize(paragraph(...content))).toBe(expected);
});

it.each`
  description                        | content                                        | expected
  ${'a dot after an issue'}          | ${[issue(1), text('.x')]}                      | ${'#1.x'}
  ${'a hyphen after an issue'}       | ${[issue(1), text('-x')]}                      | ${'#1-x'}
  ${'a slash after an issue'}        | ${[issue(1), text('/x')]}                      | ${'#1/x'}
  ${'a dot between references'}      | ${[issue(1), text('.'), issue(2)]}             | ${'#1.#2'}
  ${'a letter after a quoted label'} | ${[quotedLabel('UX Paper Cuts'), text('abc')]} | ${'~"UX Paper Cuts"abc'}
  ${'bold text after an issue'}      | ${[issue(1), bold('x')]}                       | ${'#1**x**'}
`('does not add a space between a reference and $description', ({ content, expected }) => {
  expect(serialize(paragraph(...content))).toBe(expected);
});

it('round-trips references separated by punctuation as rendered by the markdown API', async () => {
  const html = `<p dir="auto">see ${renderedReference('issue', '#1', '/gitlab-org/gitlab/-/issues/1')}/${renderedReference('issue', '#2', '/gitlab-org/gitlab/-/issues/2')}, and ${renderedReference('merge_request', '!1', '/gitlab-org/gitlab/-/merge_requests/1')}.</p>`;

  expect(await roundTrip(html)).toBe('see #1/#2, and !1.');
});

it('round-trips a quoted milestone reference as rendered by the markdown API', async () => {
  const html =
    '<p dir="auto"><a href="/gitlab-org/gitlab/-/milestones/1" class="gfm gfm-milestone" data-original="%&amp;quot;Sprint 1&amp;quot;" data-link="false" data-link-reference="false" data-reference-type="milestone">%Sprint 1</a></p>';

  expect(await roundTrip(html)).toBe('%"Sprint 1"');
});
