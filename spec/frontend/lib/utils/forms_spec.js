import { serializeForm } from '~/lib/utils/forms';

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
  });
});
