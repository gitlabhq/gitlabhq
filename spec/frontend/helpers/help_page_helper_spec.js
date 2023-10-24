import { helpPagePath } from '~/helpers/help_page_helper';

describe('help page helper', () => {
  it.each`
    relative_url_root | path                         | anchor                  | expected
    ${undefined}      | ${undefined}                 | ${undefined}            | ${'/help'}
    ${undefined}      | ${'administration/index'}    | ${undefined}            | ${'/help/administration/index'}
    ${''}             | ${'administration/index'}    | ${undefined}            | ${'/help/administration/index'}
    ${'/'}            | ${'administration/index'}    | ${undefined}            | ${'/help/administration/index'}
    ${'/gitlab'}      | ${'administration/index'}    | ${undefined}            | ${'/gitlab/help/administration/index'}
    ${'/gitlab/'}     | ${'administration/index'}    | ${undefined}            | ${'/gitlab/help/administration/index'}
    ${undefined}      | ${'administration/index'}    | ${undefined}            | ${'/help/administration/index'}
    ${'/'}            | ${'administration/index'}    | ${undefined}            | ${'/help/administration/index'}
    ${''}             | ${'administration/index.md'} | ${undefined}            | ${'/help/administration/index.md'}
    ${''}             | ${'administration/index.md'} | ${'installing-gitlab'}  | ${'/help/administration/index.md#installing-gitlab'}
    ${''}             | ${'administration/index'}    | ${'installing-gitlab'}  | ${'/help/administration/index#installing-gitlab'}
    ${''}             | ${'administration/index'}    | ${'#installing-gitlab'} | ${'/help/administration/index#installing-gitlab'}
    ${''}             | ${'/administration/index'}   | ${undefined}            | ${'/help/administration/index'}
    ${''}             | ${'administration/index/'}   | ${undefined}            | ${'/help/administration/index/'}
    ${''}             | ${'/administration/index/'}  | ${undefined}            | ${'/help/administration/index/'}
    ${'/'}            | ${'/administration/index'}   | ${undefined}            | ${'/help/administration/index'}
  `(
    'generates correct URL when path is `$path`, relative url is `$relative_url_root` and anchor is `$anchor`',
    ({ relative_url_root, anchor, path, expected }) => {
      window.gon = { relative_url_root };

      expect(helpPagePath(path, { anchor })).toBe(expected);
    },
  );
});
