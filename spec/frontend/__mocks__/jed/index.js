/**
 * ## Why are we mocking Jed?
 *
 * https://gitlab.com/gitlab-org/gitlab/-/issues/390934#note_1494028934
 *
 * It's possible that some environments run a specific locale. If the unit
 * tests run under this condition, hardcoded values will fail. To make
 * tests more deterministic across environments, let's skip loading translations
 * in FE unit tests.
 */
const Jed = jest.requireActual('jed');

export default class MockJed extends Jed {
  constructor() {
    super({});
  }
}
