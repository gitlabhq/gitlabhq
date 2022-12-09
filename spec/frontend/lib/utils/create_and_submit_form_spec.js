import csrf from '~/lib/utils/csrf';
import { TEST_HOST } from 'helpers/test_constants';
import { createAndSubmitForm } from '~/lib/utils/create_and_submit_form';
import { joinPaths } from '~/lib/utils/url_utility';

const TEST_URL = '/foo/bar/lorem';
const TEST_DATA = {
  'test_thing[0]': 'Lorem Ipsum',
  'test_thing[1]': 'Dolar Sit',
  x: 123,
};
const TEST_CSRF = 'testcsrf00==';

describe('~/lib/utils/create_and_submit_form', () => {
  let submitSpy;

  const findForm = () => document.querySelector('form');
  const findInputsModel = () =>
    Array.from(findForm().querySelectorAll('input')).map((inputEl) => ({
      type: inputEl.type,
      name: inputEl.name,
      value: inputEl.value,
    }));

  beforeEach(() => {
    submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit');
    document.head.innerHTML = `<meta name="csrf-token" content="${TEST_CSRF}">`;
    csrf.init();
  });

  afterEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
  });

  describe('default', () => {
    beforeEach(() => {
      createAndSubmitForm({
        url: TEST_URL,
        data: TEST_DATA,
      });
    });

    it('creates form', () => {
      const form = findForm();

      expect(form.action).toBe(joinPaths(TEST_HOST, TEST_URL));
      expect(form.method).toBe('post');
      expect(form.style).toMatchObject({
        display: 'none',
      });
    });

    it('creates inputs', () => {
      expect(findInputsModel()).toEqual([
        ...Object.keys(TEST_DATA).map((key) => ({
          type: 'hidden',
          name: key,
          value: String(TEST_DATA[key]),
        })),
        {
          type: 'hidden',
          name: 'authenticity_token',
          value: TEST_CSRF,
        },
      ]);
    });

    it('submits form', () => {
      expect(submitSpy).toHaveBeenCalled();
    });
  });
});
