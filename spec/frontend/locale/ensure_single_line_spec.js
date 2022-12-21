import ensureSingleLine from '~/locale/ensure_single_line.cjs';

describe('locale', () => {
  describe('ensureSingleLine', () => {
    it('should remove newlines at the start of the string', () => {
      const result = 'Test';

      expect(ensureSingleLine(`\n${result}`)).toBe(result);
      expect(ensureSingleLine(`\t\n\t${result}`)).toBe(result);
      expect(ensureSingleLine(`\r\n${result}`)).toBe(result);
      expect(ensureSingleLine(`\r\n ${result}`)).toBe(result);
      expect(ensureSingleLine(`\r ${result}`)).toBe(result);
      expect(ensureSingleLine(` \n ${result}`)).toBe(result);
    });

    it('should remove newlines at the end of the string', () => {
      const result = 'Test';

      expect(ensureSingleLine(`${result}\n`)).toBe(result);
      expect(ensureSingleLine(`${result}\t\n\t`)).toBe(result);
      expect(ensureSingleLine(`${result}\r\n`)).toBe(result);
      expect(ensureSingleLine(`${result}\r`)).toBe(result);
      expect(ensureSingleLine(`${result} \r`)).toBe(result);
      expect(ensureSingleLine(`${result} \r\n `)).toBe(result);
    });

    it('should replace newlines in the middle of the string with a single space', () => {
      const result = 'Test';

      expect(ensureSingleLine(`${result}\n${result}`)).toBe(`${result} ${result}`);
      expect(ensureSingleLine(`${result}\t\n\t${result}`)).toBe(`${result} ${result}`);
      expect(ensureSingleLine(`${result}\r\n${result}`)).toBe(`${result} ${result}`);
      expect(ensureSingleLine(`${result}\r${result}`)).toBe(`${result} ${result}`);
      expect(ensureSingleLine(`${result} \r${result}`)).toBe(`${result} ${result}`);
      expect(ensureSingleLine(`${result} \r\n ${result}`)).toBe(`${result} ${result}`);
    });
  });
});
