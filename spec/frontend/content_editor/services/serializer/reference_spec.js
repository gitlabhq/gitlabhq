import { serialize, builders } from '../../serialization_utils';

const { paragraph, reference, referenceLabel } = builders;

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
