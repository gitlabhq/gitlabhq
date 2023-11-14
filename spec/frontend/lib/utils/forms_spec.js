import {
  serializeForm,
  serializeFormObject,
  safeTrim,
  isEmptyValue,
  hasMinimumLength,
  isParseableAsInteger,
  isIntegerGreaterThan,
  isServiceDeskSettingEmail,
  isUserEmail,
  parseRailsFormFields,
} from '~/lib/utils/forms';

describe('lib/utils/forms', () => {
  const createDummyForm = (inputs) => {
    const form = document.createElement('form');

    form.innerHTML = inputs
      .map(({ type, name, value }) => {
        let str = ``;
        if (type === 'select') {
          str = `<select name="${name}">`;
          value.forEach((v) => {
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
        .mockImplementation((name) =>
          formData.map((elem) => (elem.name === name ? elem.value : undefined)),
        );

      const data = serializeForm(form);

      expect(data).toEqual({
        foo: 'foo-value1',
        bar: 'bar-value2',
      });
    });
  });

  describe('safeTrim', () => {
    it.each`
      input        | returnValue
      ${''}        | ${''}
      ${[]}        | ${[]}
      ${null}      | ${null}
      ${undefined} | ${undefined}
      ${' '}       | ${''}
      ${'hello  '} | ${'hello'}
      ${'hello'}   | ${'hello'}
      ${0}         | ${0}
    `('returns $returnValue for value $input', ({ input, returnValue }) => {
      expect(safeTrim(input)).toEqual(returnValue);
    });
  });

  describe('isEmptyValue', () => {
    it.each`
      input        | returnValue
      ${''}        | ${true}
      ${[]}        | ${true}
      ${null}      | ${true}
      ${undefined} | ${true}
      ${' '}       | ${true}
      ${'hello'}   | ${false}
      ${0}         | ${false}
    `('returns $returnValue for value $input', ({ input, returnValue }) => {
      expect(isEmptyValue(input)).toBe(returnValue);
    });
  });

  describe('hasMinimumLength', () => {
    it.each`
      input         | minLength | returnValue
      ${['o', 't']} | ${1}      | ${true}
      ${'hello'}    | ${3}      | ${true}
      ${'   '}      | ${2}      | ${false}
      ${''}         | ${0}      | ${false}
      ${''}         | ${8}      | ${false}
      ${[]}         | ${0}      | ${false}
      ${null}       | ${8}      | ${false}
      ${undefined}  | ${8}      | ${false}
      ${'hello'}    | ${8}      | ${false}
      ${0}          | ${8}      | ${false}
      ${4}          | ${1}      | ${false}
    `(
      'returns $returnValue for value $input and minLength $minLength',
      ({ input, minLength, returnValue }) => {
        expect(hasMinimumLength(input, minLength)).toBe(returnValue);
      },
    );
  });

  describe('isPareseableInteger', () => {
    it.each`
      input        | returnValue
      ${'0'}       | ${true}
      ${'12'}      | ${true}
      ${''}        | ${false}
      ${[]}        | ${false}
      ${null}      | ${false}
      ${undefined} | ${false}
      ${'hello'}   | ${false}
      ${' '}       | ${false}
      ${'12.4'}    | ${false}
      ${'12ef'}    | ${false}
    `('returns $returnValue for value $input', ({ input, returnValue }) => {
      expect(isParseableAsInteger(input)).toBe(returnValue);
    });
  });

  describe('isIntegerGreaterThan', () => {
    it.each`
      input         | greaterThan | returnValue
      ${25}         | ${8}        | ${true}
      ${'25'}       | ${8}        | ${true}
      ${'4'}        | ${1}        | ${true}
      ${'4'}        | ${8}        | ${false}
      ${'9.5'}      | ${8}        | ${false}
      ${'9.5e'}     | ${8}        | ${false}
      ${['o', 't']} | ${0}        | ${false}
      ${'hello'}    | ${0}        | ${false}
      ${'   '}      | ${0}        | ${false}
      ${''}         | ${0}        | ${false}
      ${''}         | ${8}        | ${false}
      ${[]}         | ${0}        | ${false}
      ${null}       | ${0}        | ${false}
      ${undefined}  | ${0}        | ${false}
      ${'hello'}    | ${0}        | ${false}
      ${0}          | ${0}        | ${false}
    `(
      'returns $returnValue for value $input and greaterThan $greaterThan',
      ({ input, greaterThan, returnValue }) => {
        expect(isIntegerGreaterThan(input, greaterThan)).toBe(returnValue);
      },
    );
  });

  describe('isServiceDeskSettingEmail', () => {
    it.each`
      input                                    | returnValue
      ${'user-with_special-chars@example.com'} | ${true}
      ${'user@subdomain.example.com'}          | ${true}
      ${'user@example.com'}                    | ${true}
      ${'user@example.co'}                     | ${true}
      ${'user@example.c'}                      | ${false}
      ${'user@example'}                        | ${false}
      ${''}                                    | ${false}
      ${[]}                                    | ${false}
      ${null}                                  | ${false}
      ${undefined}                             | ${false}
      ${'hello'}                               | ${false}
      ${' '}                                   | ${false}
      ${'12'}                                  | ${false}
    `('returns $returnValue for value $input', ({ input, returnValue }) => {
      expect(isServiceDeskSettingEmail(input)).toBe(returnValue);
    });
  });

  describe('isUserEmail', () => {
    it.each`
      input                                    | returnValue
      ${'user-with_special-chars@example.com'} | ${true}
      ${'user@subdomain.example.com'}          | ${true}
      ${'user@example.com'}                    | ${true}
      ${'user@example.co'}                     | ${true}
      ${'user@example.c'}                      | ${true}
      ${'user@example'}                        | ${true}
      ${''}                                    | ${false}
      ${[]}                                    | ${false}
      ${null}                                  | ${false}
      ${undefined}                             | ${false}
      ${'hello'}                               | ${false}
      ${' '}                                   | ${false}
      ${'12'}                                  | ${false}
    `('returns $returnValue for value $input', ({ input, returnValue }) => {
      expect(isUserEmail(input)).toBe(returnValue);
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

  describe('parseRailsFormFields', () => {
    let mountEl;

    beforeEach(() => {
      mountEl = document.createElement('div');
      mountEl.classList.add('js-foo-bar');
    });

    afterEach(() => {
      mountEl = null;
    });

    it('parses fields generated by Rails and returns object with HTML attributes', () => {
      mountEl.innerHTML = `
        <input type="text" placeholder="Name" value="Administrator" name="user[name]" id="user_name" data-js-name="name">
        <input type="text" placeholder="Email" value="foo@bar.com" name="user[contact_info][email]" id="user_contact_info_email" data-js-name="contactInfoEmail">
        <input type="text" placeholder="Phone" value="(123) 456-7890" name="user[contact_info][phone]" id="user_contact_info_phone" maxlength="12" pattern="mockPattern" data-js-name="contact_info_phone">
        <input type="hidden" placeholder="Job title" value="" name="user[job_title]" id="user_job_title" data-js-name="jobTitle">
        <textarea name="user[bio]" id="user_bio" data-js-name="bio">Foo bar</textarea>
        <select name="user[timezone]" id="user_timezone" data-js-name="timezone">
          <option value="utc+12">[UTC - 12] International Date Line West</option>
          <option value="utc+11" selected>[UTC - 11] American Samoa</option>
        </select>
        <input type="checkbox" name="user[interests][]" id="user_interests_vue" value="Vue" checked data-js-name="interests">
        <input type="checkbox" name="user[interests][]" id="user_interests_graphql" value="GraphQL" data-js-name="interests">
        <input type="radio" name="user[access_level]" value="regular" id="user_access_level_regular" data-js-name="accessLevel">
        <input type="radio" name="user[access_level]" value="admin" id="user_access_level_admin" checked data-js-name="access_level">
        <input name="user[private_profile]" type="hidden" value="0">
        <input type="radio" name="user[private_profile]" id="user_private_profile" value="1" checked data-js-name="privateProfile">
        <input name="user[email_notifications]" type="hidden" value="0">
        <input type="radio" name="user[email_notifications]" id="user_email_notifications" value="1" data-js-name="emailNotifications">
      `;

      expect(parseRailsFormFields(mountEl)).toEqual({
        name: {
          name: 'user[name]',
          id: 'user_name',
          value: 'Administrator',
          placeholder: 'Name',
        },
        contactInfoEmail: {
          name: 'user[contact_info][email]',
          id: 'user_contact_info_email',
          value: 'foo@bar.com',
          placeholder: 'Email',
        },
        contactInfoPhone: {
          name: 'user[contact_info][phone]',
          id: 'user_contact_info_phone',
          value: '(123) 456-7890',
          placeholder: 'Phone',
          maxLength: 12,
          pattern: 'mockPattern',
        },
        jobTitle: {
          name: 'user[job_title]',
          id: 'user_job_title',
          value: '',
          placeholder: 'Job title',
        },
        bio: {
          name: 'user[bio]',
          id: 'user_bio',
          value: 'Foo bar',
        },
        timezone: {
          name: 'user[timezone]',
          id: 'user_timezone',
          value: 'utc+11',
        },
        interests: [
          {
            name: 'user[interests][]',
            id: 'user_interests_vue',
            value: 'Vue',
            checked: true,
          },
          {
            name: 'user[interests][]',
            id: 'user_interests_graphql',
            value: 'GraphQL',
            checked: false,
          },
        ],
        accessLevel: [
          {
            name: 'user[access_level]',
            id: 'user_access_level_regular',
            value: 'regular',
            checked: false,
          },
          {
            name: 'user[access_level]',
            id: 'user_access_level_admin',
            value: 'admin',
            checked: true,
          },
        ],
        privateProfile: [
          {
            name: 'user[private_profile]',
            id: 'user_private_profile',
            value: '1',
            checked: true,
          },
        ],
        emailNotifications: [
          {
            name: 'user[email_notifications]',
            id: 'user_email_notifications',
            value: '1',
            checked: false,
          },
        ],
      });
    });

    it('returns an empty object if there are no inputs', () => {
      expect(parseRailsFormFields(mountEl)).toEqual({});
    });

    it('returns an empty object if inputs do not have `name` attributes', () => {
      mountEl.innerHTML = `
        <input type="text" placeholder="Name" value="Administrator" id="user_name">
        <input type="text" placeholder="Email" value="foo@bar.com" id="user_contact_info_email">
        <input type="text" placeholder="Phone" value="(123) 456-7890" id="user_contact_info_phone">
      `;

      expect(parseRailsFormFields(mountEl)).toEqual({});
    });

    it('does not include field if `data-js-name` attribute is missing', () => {
      mountEl.innerHTML = `
        <input type="text" placeholder="Name" value="Administrator" name="user[name]" id="user_name" data-js-name="name">
        <input type="text" placeholder="Email" value="foo@bar.com" name="user[email]" id="email">
      `;

      expect(parseRailsFormFields(mountEl)).toEqual({
        name: {
          name: 'user[name]',
          id: 'user_name',
          value: 'Administrator',
          placeholder: 'Name',
        },
      });
    });

    it('throws error if `mountEl` argument is not passed', () => {
      expect(() => parseRailsFormFields()).toThrow(new TypeError('`mountEl` argument is required'));
    });

    it('throws error if `mountEl` argument is `null`', () => {
      expect(() => parseRailsFormFields(null)).toThrow(
        new TypeError('`mountEl` argument is required'),
      );
    });
  });
});
