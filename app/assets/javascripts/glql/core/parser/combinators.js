import { __ } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';

const success = (value, rest) => ({ success: true, value, rest });
const error = (expected, got) => ({ success: false, expected, got });

export const Parser = (parserFn) => ({
  run: parserFn,
  map(fn) {
    return Parser((input) => {
      const result = this.run(input);
      return result.success ? { ...result, value: fn(result.value) } : result;
    });
  },
  chain(fn) {
    return Parser((input) => {
      const result = this.run(input);
      return result.success ? fn(result.value).run(result.rest) : result;
    });
  },
});

export const str = (s) =>
  Parser((input) =>
    input.startsWith(s) ? success(s, input.slice(s.length)) : error(s, input.slice(0, s.length)),
  );

export const regex = (re, description) =>
  Parser((input) => {
    const match = input.match(re);
    return match && match.index === 0
      ? success(match[0], input.slice(match[0].length))
      : error(description, truncate(input, 10));
  });

export const seq = (...parsers) =>
  Parser((input) => {
    const results = [];
    let currentInput = input;
    for (const parser of parsers) {
      const result = parser.run(currentInput);
      if (!result.success) return result;
      results.push(result.value);
      currentInput = result.rest;
    }
    return success(results, currentInput);
  });

export const alt = (...parsers) =>
  Parser((input) => {
    for (const parser of parsers) {
      const result = parser.run(input);
      if (result.success) return result;
    }
    return error(__('something to parse'), truncate(input, 10));
  });

export const many = (parser) =>
  Parser((input) => {
    const results = [];
    let currentInput = input;
    let result;
    do {
      result = parser.run(currentInput);
      if (result.success) {
        results.push(result.value);
        currentInput = result.rest;
      }
    } while (result.success);

    return success(results, currentInput);
  });

export const optional = (parser) =>
  alt(
    parser,
    Parser((input) => success(null, input)),
  );

export const whitespace = regex(/^\s+/, 'whitespace');

export const token = (parser) => seq(optional(whitespace), parser).map(([, t]) => t);
