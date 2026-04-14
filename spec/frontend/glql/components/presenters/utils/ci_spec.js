import { ciStatusToIcon } from '~/glql/components/presenters/utils/ci';

describe('ciStatusToIcon', () => {
  it.each`
    status         | expectedIcon          | expectedText
    ${'success'}   | ${'status_success'}   | ${'Passed'}
    ${'failed'}    | ${'status_failed'}    | ${'Failed'}
    ${'running'}   | ${'status_running'}   | ${'Running'}
    ${'pending'}   | ${'status_pending'}   | ${'Pending'}
    ${'canceled'}  | ${'status_canceled'}  | ${'Canceled'}
    ${'skipped'}   | ${'status_skipped'}   | ${'Skipped'}
    ${'manual'}    | ${'status_manual'}    | ${'Manual'}
    ${'created'}   | ${'status_created'}   | ${'Created'}
    ${'preparing'} | ${'status_preparing'} | ${'Preparing'}
    ${'scheduled'} | ${'status_scheduled'} | ${'Scheduled'}
  `(
    'returns icon "$expectedIcon" and text "$expectedText" for "$status"',
    ({ status, expectedIcon, expectedText }) => {
      const result = ciStatusToIcon(status);

      expect(result).toEqual({ icon: expectedIcon, text: expectedText });
    },
  );

  it('normalizes uppercase status values', () => {
    const result = ciStatusToIcon('SUCCESS');

    expect(result).toEqual({ icon: 'status_success', text: 'Passed' });
  });

  it('returns null for unknown status', () => {
    expect(ciStatusToIcon('unknown_status')).toBeNull();
  });

  it.each([null, undefined])('returns null for %s status', (status) => {
    expect(ciStatusToIcon(status)).toBeNull();
  });
});
