import Ajv from 'ajv';
import AjvFormats from 'ajv-formats';

const JSON_SCHEMA = {
  type: 'object',
  properties: {
    fruit: {
      type: 'string',
      minLength: 3,
    },
  },
};

const ajv = new Ajv({
  strictTypes: false,
  strictTuples: false,
  allowMatchingProperties: true,
});

AjvFormats(ajv);
const schema = ajv.compile(JSON_SCHEMA);

describe('custom matcher toValidateJsonSchema', () => {
  it('throws error if validator is not compiled correctly', () => {
    expect(() => {
      expect({}).toValidateJsonSchema({});
    }).toThrow(
      'Validator must be a validating function with property "schema", created with `ajv.compile`. See https://ajv.js.org/api.html#ajv-compile-schema-object-data-any-boolean-promise-any.',
    );
  });

  describe('positive assertions', () => {
    it.each`
      description      | input
      ${'valid input'} | ${{ fruit: 'apple' }}
    `('schema validation passes for $description', ({ input }) => {
      expect(input).toValidateJsonSchema(schema);
    });

    it('throws if not matching', () => {
      expect(() => expect(null).toValidateJsonSchema(schema)).toThrow(
        `Expected the given data to pass the schema validation, but found that it was considered invalid. Errors:
Error with item : must be object`,
      );
    });
  });

  describe('negative assertions', () => {
    it.each`
      description                    | input
      ${'no input'}                  | ${null}
      ${'input with invalid type'}   | ${'banana'}
      ${'input with invalid length'} | ${{ fruit: 'aa' }}
      ${'input with invalid type'}   | ${{ fruit: 12345 }}
    `('schema validation fails for $description', ({ input }) => {
      expect(input).not.toValidateJsonSchema(schema);
    });

    it('throws if matching', () => {
      expect(() => expect({ fruit: 'apple' }).not.toValidateJsonSchema(schema)).toThrow(
        'Expected the given data not to pass the schema validation, but found that it was considered valid.',
      );
    });
  });
});
