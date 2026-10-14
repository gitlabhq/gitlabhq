import { serialize, builders, roundTrip } from '../../serialization_utils';

const renderedLabel = (original, name) =>
  `<p dir="auto"><span class="gl-label"><a href="/gitlab-org/gitlab/-/issues?label_name=${name}" class="gfm gfm-label has-tooltip gl-link gl-label-link" data-original="${original}" data-link="false" data-link-reference="false" data-reference-type="label"><span class="gl-label-text gl-label-text-light" style="background-color: #cc338b">${name}</span></a></span></p>`;

const { paragraph, referenceLabel } = builders;

it('correctly renders a reference label', () => {
  expect(
    serialize(
      paragraph(
        referenceLabel({
          referenceType: 'label',
          originalText: '~foo',
          href: '/gitlab-org/gitlab-test/-/labels/foo',
          text: '~foo',
        }),
      ),
    ),
  ).toBe('~foo');
});

it('correctly renders a reference label without originalText', () => {
  expect(
    serialize(
      paragraph(
        referenceLabel({
          referenceType: 'label',
          href: '/gitlab-org/gitlab-test/-/labels/foo',
          text: 'Foo Bar',
        }),
      ),
    ),
  ).toBe('~"Foo Bar"');
});

it.each`
  description                      | html                                                                                | expected
  ${'a label with spaces'}         | ${renderedLabel('~&amp;quot;UX Paper Cuts&amp;quot;', 'UX Paper Cuts')}             | ${'~"UX Paper Cuts"'}
  ${'a label with an ampersand'}   | ${renderedLabel('~&amp;quot;Docs &amp;amp; Guides&amp;quot;', 'Docs &amp; Guides')} | ${'~"Docs & Guides"'}
  ${'a label with angle brackets'} | ${renderedLabel('~&amp;quot;a &amp;lt;b&amp;gt; c&amp;quot;', 'a &lt;b&gt; c')}     | ${'~"a \\<b\\> c"'}
  ${'a label without quotes'}      | ${renderedLabel('~bug', 'bug')}                                                     | ${'~bug'}
`('round-trips $description as rendered by the markdown API', async ({ html, expected }) => {
  expect(await roundTrip(html)).toBe(expected);
});
