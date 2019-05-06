import { hasQuickActions } from '~/notes/stores/utils';

describe('hasQuickActions', () => {
  it.each`
    input                                | expected
    ${'some comment'}                    | ${false}
    ${'/quickaction'}                    | ${true}
    ${'some comment with\n/quickaction'} | ${true}
  `('returns $expected for $input', ({ input, expected }) => {
    expect(hasQuickActions(input)).toBe(expected);
  });

  it('is stateless', () => {
    expect(hasQuickActions('some comment')).toBe(hasQuickActions('some comment'));
    expect(hasQuickActions('/quickaction')).toBe(hasQuickActions('/quickaction'));
  });
});
