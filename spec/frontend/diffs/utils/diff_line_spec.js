import { pickDirection } from '~/diffs/utils/diff_line';

describe('diff_line utilities', () => {
  describe('pickDirection', () => {
    const left = {
      line_code: 'left',
    };
    const right = {
      line_code: 'right',
    };
    const defaultLine = {
      left,
      right,
    };

    it.each`
      code       | pick     | line           | pickDescription
      ${'left'}  | ${left}  | ${defaultLine} | ${'the left line'}
      ${'right'} | ${right} | ${defaultLine} | ${'the right line'}
      ${'junk'}  | ${left}  | ${defaultLine} | ${'the default: the left line'}
      ${'junk'}  | ${right} | ${{ right }}   | ${"the right line if there's no left line to default to"}
      ${'right'} | ${left}  | ${{ left }}    | ${"the left line when there isn't a right line to match"}
    `(
      'when provided a line and a line code `$code`, picks $pickDescription',
      ({ code, line, pick }) => {
        expect(pickDirection({ line, code })).toBe(pick);
      },
    );
  });
});
