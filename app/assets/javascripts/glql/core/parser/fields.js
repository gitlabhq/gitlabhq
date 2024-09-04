import { sprintf, __ } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import { alt, many, optional, regex, seq, str, token } from './combinators';
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

const leftParen = token(str('('));
const rightParen = token(str(')'));
const comma = token(str(','));

const functionName = token(regex(/^[a-z_][a-z0-9_]*/i, __('function name')));
const functionArgs = optional(sepBy(string, comma));
const functionCall = seq(functionName, leftParen, functionArgs, rightParen).map(([name, , args]) =>
  ast.functionCall(name, args),
);

const value = alt(functionCall, fieldName);
const parser = sepBy(value, comma);

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
