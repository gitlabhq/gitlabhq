import { TEST_HOST } from 'helpers/test_constants';
import {
  DEFAULT_PLATFORM,
  LINUX_PLATFORM,
  MACOS_PLATFORM,
  WINDOWS_PLATFORM,
} from '~/ci/runner/constants';

import {
  commandPrompt,
  registerCommand,
  runCommand,
  installScript,
  platformArchitectures,
} from '~/ci/runner/components/registration/utils';

const REGISTRATION_TOKEN = 'REGISTRATION_TOKEN';
const DESCRIPTION = 'RUNNER';

describe('registration utils', () => {
  beforeEach(() => {
    window.gon.gitlab_url = TEST_HOST;
  });

  describe.each([LINUX_PLATFORM, MACOS_PLATFORM, WINDOWS_PLATFORM])(
    'for "%s" platform',
    (platform) => {
      it('commandPrompt is correct', () => {
        expect(commandPrompt({ platform })).toMatchSnapshot();
      });

      it('registerCommand is correct', () => {
        expect(
          registerCommand({
            platform,
            registrationToken: REGISTRATION_TOKEN,
            description: DESCRIPTION,
          }),
        ).toMatchSnapshot();

        expect(registerCommand({ platform })).toMatchSnapshot();
      });

      it('runCommand is correct', () => {
        expect(runCommand({ platform })).toMatchSnapshot();
      });
    },
  );

  describe.each([LINUX_PLATFORM, MACOS_PLATFORM])('for "%s" platform', (platform) => {
    it.each`
      description       | parameter
      ${'my runner'}    | ${"'my runner'"}
      ${"bob's runner"} | ${"'bob'\\''s runner'"}
    `('registerCommand escapes description `$description`', ({ description, parameter }) => {
      expect(registerCommand({ platform, description })[2]).toBe(`  --description ${parameter}`);
    });
  });

  describe.each([WINDOWS_PLATFORM])('for "%s" platform', (platform) => {
    it.each`
      description       | parameter
      ${'my runner'}    | ${"'my runner'"}
      ${"bob's runner"} | ${"'bob''s runner'"}
    `('registerCommand escapes description `$description`', ({ description, parameter }) => {
      expect(registerCommand({ platform, description })[2]).toBe(`  --description ${parameter}`);
    });
  });

  describe('for missing platform', () => {
    it('commandPrompt uses the default', () => {
      const expected = commandPrompt({ platform: DEFAULT_PLATFORM });

      expect(commandPrompt({ platform: null })).toEqual(expected);
      expect(commandPrompt({ platform: undefined })).toEqual(expected);
    });

    it('registerCommand uses the default', () => {
      const expected = registerCommand({
        platform: DEFAULT_PLATFORM,
        registrationToken: REGISTRATION_TOKEN,
      });

      expect(registerCommand({ platform: null, registrationToken: REGISTRATION_TOKEN })).toEqual(
        expected,
      );
      expect(
        registerCommand({ platform: undefined, registrationToken: REGISTRATION_TOKEN }),
      ).toEqual(expected);
    });

    it('runCommand uses the default', () => {
      const expected = runCommand({ platform: DEFAULT_PLATFORM });

      expect(runCommand({ platform: null })).toEqual(expected);
      expect(runCommand({ platform: undefined })).toEqual(expected);
    });
  });

  describe.each([LINUX_PLATFORM, MACOS_PLATFORM, WINDOWS_PLATFORM])(
    'for "%s" platform',
    (platform) => {
      describe('platformArchitectures', () => {
        it('returns correct list of architectures', () => {
          expect(platformArchitectures({ platform })).toMatchSnapshot();
        });
      });

      describe('installScript', () => {
        const architectures = platformArchitectures({ platform });

        it.each(architectures)('is correct for "%s" architecture', (architecture) => {
          expect(installScript({ platform, architecture })).toMatchSnapshot();
        });
      });
    },
  );
});
