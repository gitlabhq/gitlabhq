import { isEnforcementRow } from '~/vue_shared/components/settings/utils';

describe('settings utils', () => {
  describe('isEnforcementRow', () => {
    const policy = { name: 'Request access review', webPath: '/policies/1' };

    it.each`
      description                 | row                                           | expected
      ${'an enforce row'}         | ${{ mode: 'enforce', policy }}                | ${true}
      ${'a warn row'}             | ${{ mode: 'warn', policy }}                   | ${true}
      ${'an audit row'}           | ${{ mode: 'audit', policy }}                  | ${true}
      ${'a row without webPath'}  | ${{ mode: 'enforce', policy: { name: 'P' } }} | ${true}
      ${'an unknown mode'}        | ${{ mode: 'block', policy }}                  | ${false}
      ${'a row without a mode'}   | ${{ policy }}                                 | ${false}
      ${'a row without a policy'} | ${{ mode: 'enforce' }}                        | ${false}
      ${'a nameless policy'}      | ${{ mode: 'enforce', policy: { name: 1 } }}   | ${false}
      ${'null'}                   | ${null}                                       | ${false}
      ${'undefined'}              | ${undefined}                                  | ${false}
    `('returns $expected for $description', ({ row, expected }) => {
      expect(isEnforcementRow(row)).toBe(expected);
    });
  });
});
