import { serialize, builders } from '../../serialization_utils';

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
