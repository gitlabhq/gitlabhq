import { getAjaxUsersSelectParams } from '~/users_select/utils';

const options = {
  fooBar: 'baz',
  activeUserId: 1,
};

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
