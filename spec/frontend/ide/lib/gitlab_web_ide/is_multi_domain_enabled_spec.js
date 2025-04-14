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
    dot_com  | features | expected
    ${true}  | ${true}  | ${true}
    ${true}  | ${false} | ${false}
    ${false} | ${true}  | ${false}
    ${false} | ${false} | ${false}
  `(
    'returns $expected when gon.dot_com is $dot_com and gon.features.webIdeMultiDomain is $features',
    ({ dot_com, features, expected }) => {
      window.gon = {
        dot_com,
        features: {
          webIdeMultiDomain: features,
        },
      };

      expect(isMultiDomainEnabled()).toBe(expected);
    },
  );
});
