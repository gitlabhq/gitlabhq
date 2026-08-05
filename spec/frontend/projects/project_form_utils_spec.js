import { setOrRemoveAttribute } from '~/projects/project_form_utils';

describe('setOrRemoveAttribute', () => {
  let el;

  beforeEach(() => {
    el = document.createElement('input');
    el.setAttribute('aria-describedby', 'some-id');
  });

  it.each`
    description                 | value        | expected
    ${'sets the attribute'}     | ${'new-id'}  | ${'new-id'}
    ${'removes when null'}      | ${null}      | ${null}
    ${'removes when undefined'} | ${undefined} | ${null}
  `('$description', ({ value, expected }) => {
    setOrRemoveAttribute(el, 'aria-describedby', value);

    expect(el.getAttribute('aria-describedby')).toBe(expected);
  });
});
