import { appendWidthToAvatarUrl } from '~/vue_shared/components/user_avatar/utils';

describe('appendWidthToAvatarUrl', () => {
  it.each`
    description                                              | url                                       | expected
    ${'as the first query parameter when URL has no params'} | ${'https://example.com/avatar.png'}       | ${'https://example.com/avatar.png?width=48'}
    ${'with & when URL already has query params'}            | ${'https://example.com/avatar.png?v=123'} | ${'https://example.com/avatar.png?v=123&width=48'}
  `('appends width $description', ({ url, expected }) => {
    expect(appendWidthToAvatarUrl(url, 48)).toBe(expected);
  });

  it.each`
    description                            | url                                                                             | expected
    ${'URL already has a width parameter'} | ${'https://example.com/avatar.png?width=32'}                                    | ${'https://example.com/avatar.png?width=32'}
    ${'URL has width among other params'}  | ${'https://example.com/avatar.png?width=32&v=123'}                              | ${'https://example.com/avatar.png?width=32&v=123'}
    ${'data: URI'}                         | ${'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='} | ${'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='}
    ${'null value'}                        | ${null}                                                                         | ${null}
    ${'empty string'}                      | ${''}                                                                           | ${''}
  `('returns the URL unchanged for $description', ({ url, expected }) => {
    expect(appendWidthToAvatarUrl(url, 48)).toBe(expected);
  });
});
