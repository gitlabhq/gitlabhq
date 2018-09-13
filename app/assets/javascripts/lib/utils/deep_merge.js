import _ from 'underscore';

function isMergeable(obj) {
  return obj && _.isObject(obj);
}

function deepMergeInto(dest, source) {
  return Object.keys(source)
    .reduce((acc, key) => Object.assign(acc, {
      [key]: isMergeable(acc[key]) && isMergeable(source[key])
        ? deepMergeInto({ ...acc[key] }, source[key])
        : source[key],
    }), dest);
}

/**
 * Return a deeply merge of the given objects
 *
 * Rules:
 * - Objects are merged from left to right.
 * - Values are merged only if they are mergeable,
 *   otherwise the left value is replaced with the right value.
 * - Immutable.
 *
 * Example:
 ```javascript
 const a = {
   foo: { val: 1 },
   bar: 'abc',
   zoo: {},
 };
 const b = {
   foo: { reason: 'math' },
   bar: 'abc/abc',
   zoo: null,
 };
 const result = deepMerge(a, b);

 // result is
 // {
 //   foo: { val: 1, reason: 'math' },
 //   bar: 'abc/abc',
 //   zoo: null,
 // }
 ```
 *
 * @param  {...any} args
 */
export default function deepMerge(...objs) {
  return objs.reduce(deepMergeInto, {});
}
