import { serializeForm, serializeFormObject, isEmptyValue } from '~/lib/utils/forms';

describe('lib/utils/forms', () => {
  const createDummyForm = inputs => {
    const form = document.createElement('form');

    form.innerHTML = inputs
      .map(({ type, name, value }) => {
        let str = ``;
        if (type === 'select') {
          str = `<select name="${name}">`;
          value.forEach(v => {
            if (v.length > 0) {
              str += `<option value="${v}"></option> `;
            }
          });
          str += `</select>`;
        } else {
          str = `<input type="${type}" name="${name}" value="${value}" checked/>`;
        }
        return str;
      })
      .join('');

    return form;
  };

  describe('serializeForm', () => {
    it('returns an object of key values from inputs', () => {
      const form = createDummyForm([
        { type: 'text', name: 'foo', value: 'foo-value' },
        { type: 'text', name: 'bar', value: 'bar-value' },
      ]);

      const data = serializeForm(form);

      expect(data).toEqual({
        foo: 'foo-value',
        bar: 'bar-value',
      });
    });

    it('works with select', () => {
      const form = createDummyForm([
        { type: 'select', name: 'foo', value: ['foo-value1', 'foo-value2'] },
        { type: 'text', name: 'bar', value: 'bar-value1' },
      ]);

      const data = serializeForm(form);

      expect(data).toEqual({
        foo: 'foo-value1',
        bar: 'bar-value1',
      });
    });

    it('works with multiple inputs of the same name', () => {
      const form = createDummyForm([
        { type: 'checkbox', name: 'foo', value: 'foo-value3' },
        { type: 'checkbox', name: 'foo', value: 'foo-value2' },
        { type: 'checkbox', name: 'foo', value: 'foo-value1' },
        { type: 'text', name: 'bar', value: 'bar-value2' },
        { type: 'text', name: 'bar', value: 'bar-value1' },
      ]);

      const data = serializeForm(form);

      expect(data).toEqual({
        foo: ['foo-value3', 'foo-value2', 'foo-value1'],
        bar: ['bar-value2', 'bar-value1'],
      });
    });

    it('handles Microsoft Edge FormData.getAll() bug', () => {
      const formData = [
        { type: 'checkbox', name: 'foo', value: 'foo-value1' },
        { type: 'text', name: 'bar', value: 'bar-value2' },
      ];

      const form = createDummyForm(formData);

      jest
        .spyOn(FormData.prototype, 'getAll')
        .mockImplementation(name =>
          formData.map(elem => (elem.name === name ? elem.value : undefined)),
        );

      const data = serializeForm(form);

      expect(data).toEqual({
        foo: 'foo-value1',
        bar: 'bar-value2',
      });
    });
  });

  describe('isEmptyValue', () => {
    it.each`
      input        | returnValue
      ${''}        | ${true}
      ${[]}        | ${true}
      ${null}      | ${true}
      ${undefined} | ${true}
      ${'hello'}   | ${false}
      ${' '}       | ${false}
      ${0}         | ${false}
    `('returns $returnValue for value $input', ({ input, returnValue }) => {
      expect(isEmptyValue(input)).toBe(returnValue);
    });
  });

  describe('serializeFormObject', () => {
    it('returns an serialized object', () => {
      const form = {
        profileName: { value: 'hello', state: null, feedback: null },
        spiderTimeout: { value: 2, state: true, feedback: null },
        targetTimeout: { value: 12, state: true, feedback: null },
      };
      expect(serializeFormObject(form)).toEqual({
        profileName: 'hello',
        spiderTimeout: 2,
        targetTimeout: 12,
      });
    });

    it('returns only the entries with value', () => {
      const form = {
        profileName: { value: '', state: null, feedback: null },
        spiderTimeout: { value: 0, state: null, feedback: null },
        targetTimeout: { value: null, state: null, feedback: null },
        name: { value: undefined, state: null, feedback: null },
      };
      expect(serializeFormObject(form)).toEqual({
        spiderTimeout: 0,
      });
    });
  });
});
