import { sprintf, __ } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import { alt, many, optional, regex, seq, tag, tagNoCase, token } from './combinators';
import * as ast from './ast';

const fieldName = token(regex(/^[a-z_][a-z0-9_]*/i, __('field name'))).map((name) =>
  ast.fieldName(name),
);

const string = token(regex(/^"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/, __('string'))).map((s) =>
  ast.string(s.slice(1, -1)),
);

const sepBy = (parser, separator) =>
  seq(parser, many(seq(separator, parser))).map(([first, rest]) =>
    ast.collection(first, ...rest.map(([, item]) => item)),
  );

const leftParen = token(tag('('));
const rightParen = token(tag(')'));
const comma = token(tag(','));
const as = token(tagNoCase('as'));

const functionName = token(regex(/^[a-z_][a-z0-9_]*/i, __('function name')));
const functionArgs = optional(sepBy(string, comma));
const functionCall = seq(functionName, leftParen, functionArgs, rightParen).map(([name, , args]) =>
  ast.functionCall(name, args),
);

const value = alt(functionCall, fieldName);
const valueWithAlias = seq(value, as, string).map(([v, , alias]) => v.withAlias(alias));
const parser = sepBy(alt(valueWithAlias, value), comma);

// Parser function
export const parseFields = (input) => {
  const result = parser.run(input);
  const rest = result.rest.trim();
  if (rest)
    throw new Error(
      sprintf(__('Parse error: Unexpected input near `%{input}`.'), {
        input: truncate(rest, 10),
      }),
    );

  if (result.success) return result.value;

  throw new Error(sprintf(__('Parse error: Expected `%{expected}`, but got `%{got}`.'), result));
};
