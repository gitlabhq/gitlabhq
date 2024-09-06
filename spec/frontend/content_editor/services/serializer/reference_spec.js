import { serialize, builders, text } from '../../serialization_utils';

const { paragraph, reference, referenceLabel, bold, italic, code, strike } = builders;

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
