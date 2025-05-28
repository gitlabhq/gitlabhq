import { isMultiDomainEnabled } from '~/ide/lib/gitlab_web_ide/is_multi_domain_enabled';

describe('isMultiDomainEnabled', () => {
  let originalGon;

  beforeEach(() => {
    originalGon = window.gon;
    window.gon = {};
  });

  afterEach(() => {
    window.gon = originalGon;
  });

  it.each`
    dot_com  | expected
    ${true}  | ${true}
    ${false} | ${false}
  `('returns $expected when gon.dot_com is $dot_com', ({ dot_com, expected }) => {
    window.gon = {
      dot_com,
    };

    expect(isMultiDomainEnabled()).toBe(expected);
  });
});
