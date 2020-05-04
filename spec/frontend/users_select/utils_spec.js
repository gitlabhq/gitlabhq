import $ from 'jquery';
import { getAjaxUsersSelectOptions, getAjaxUsersSelectParams } from '~/users_select/utils';

const options = {
  fooBar: 'baz',
  activeUserId: 1,
};

describe('getAjaxUsersSelectOptions', () => {
  it('returns options built from select data attributes', () => {
    const $select = $('<select />', { 'data-foo-bar': 'baz', 'data-user-id': 1 });

    expect(
      getAjaxUsersSelectOptions($select, { fooBar: 'fooBar', activeUserId: 'user-id' }),
    ).toEqual(options);
  });
});

describe('getAjaxUsersSelectParams', () => {
  it('returns query parameters built from provided options', () => {
    expect(
      getAjaxUsersSelectParams(options, {
        foo_bar: 'fooBar',
        active_user_id: 'activeUserId',
        non_existent_key: 'nonExistentKey',
      }),
    ).toEqual({
      foo_bar: 'baz',
      active_user_id: 1,
      non_existent_key: null,
    });
  });
});
