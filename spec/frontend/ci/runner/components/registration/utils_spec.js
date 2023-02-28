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
} from '~/ci/runner/components/registration/utils';

const REGISTRATION_TOKEN = 'REGISTRATION_TOKEN';
const DUMMY_GON = {
  gitlab_url: TEST_HOST,
};

describe('registration utils', () => {
  let originalGon;

  beforeAll(() => {
    originalGon = window.gon;
    window.gon = { ...DUMMY_GON };
  });

  afterAll(() => {
    window.gon = originalGon;
  });

  describe.each([DEFAULT_PLATFORM, LINUX_PLATFORM, MACOS_PLATFORM, WINDOWS_PLATFORM, null])(
    'for "%s" platform',
    (platform) => {
      describe('commandPrompt', () => {
        it('matches snapshot', () => {
          expect(commandPrompt({ platform })).toMatchSnapshot();
        });
      });
      describe('registerCommand', () => {
        it('matches snapshot', () => {
          expect(
            registerCommand({ platform, registrationToken: REGISTRATION_TOKEN }),
          ).toMatchSnapshot();
        });
      });
      describe('runCommand', () => {
        it('matches snapshot', () => {
          expect(runCommand({ platform })).toMatchSnapshot();
        });
      });
    },
  );
});
