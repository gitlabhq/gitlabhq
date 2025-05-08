import { camelizeKeys, transformKeys } from '~/lib/utils/object_utils';

describe('Object utils', () => {
  describe('#transformKeys', () => {
    it('transforms object keys', () => {
      const transformer = (key) => `${key}1`;
      expect(transformKeys({ foo: 1 }, transformer)).toStrictEqual({ foo1: 1 });
    });
  });

  describe('#camelizeKeys', () => {
    it('transforms object keys to camelCase', () => {
      expect(camelizeKeys({ foo_bar: 1 })).toStrictEqual({ fooBar: 1 });
    });
  });
});
