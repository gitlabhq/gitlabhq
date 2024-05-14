import { AnsiEvaluator } from '~/ci/job_log_viewer/lib/ansi_evaluator';

describe('AnsiEvaluator', () => {
  let ansi;

  beforeEach(() => {
    ansi = new AnsiEvaluator();
  });

  it('parses empty stack', () => {
    ansi.evaluate('');

    expect(ansi.getClasses()).toEqual([]);
  });

  it('parses no style', () => {
    ansi.evaluate('0m');

    expect(ansi.getClasses()).toEqual([]);
  });

  it('parses bold', () => {
    ansi.evaluate('1m');

    expect(ansi.getClasses()).toEqual(['term-bold']);
  });

  it('parses cyan', () => {
    ansi.evaluate('36m');

    expect(ansi.getClasses()).toEqual(['xterm-fg-14']);
  });

  it('parses  cyan + bold', () => {
    ansi.evaluate('36;1m');

    expect(ansi.getClasses()).toEqual(['xterm-fg-14', 'term-bold']);
  });

  it('parses green + bold', () => {
    ansi.evaluate('32;1m');

    expect(ansi.getClasses()).toEqual(['xterm-fg-10', 'term-bold']);
  });

  it('parses "set foreground color"', () => {
    ansi.evaluate('38;5;100m');

    expect(ansi.getClasses()).toEqual(['xterm-fg-100']);
  });

  it('parses "set background color"', () => {
    ansi.evaluate('48;5;100m');

    expect(ansi.getClasses()).toEqual(['xterm-bg-100']);
  });

  it('parses "set foreground color" + "set background color"', () => {
    ansi.evaluate('48;5;100;38;5;100m');

    expect(ansi.getClasses()).toEqual(['xterm-fg-100', 'xterm-bg-100']);
  });

  it('parses non-color styles', () => {
    ansi.evaluate('1;3;4;8;9m');

    expect(ansi.getClasses()).toEqual([
      'term-bold',
      'term-italic',
      'term-underline',
      'term-conceal',
      'term-cross',
    ]);
  });

  it('parses styles that get a reset', () => {
    ansi.evaluate('1;3;4;8;9;0m');

    expect(ansi.getClasses()).toEqual([]);
  });

  it('safely parses non-ansi string', () => {
    ansi.evaluate('0K');

    expect(ansi.getClasses()).toEqual([]);
  });

  it('safely parses unknown command', () => {
    ansi.evaluate('1000m');

    expect(ansi.getClasses()).toEqual([]);
  });

  it('safely parses unknown color keeping previous colors', () => {
    ansi.evaluate('48;5;100;48;5;256m');

    expect(ansi.getClasses()).toEqual(['xterm-bg-100']);
  });
});
