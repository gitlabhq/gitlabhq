import * as experimentUtils from '~/lib/utils/experimentation';

const TEST_KEY = 'abc';

describe('experiment Utilities', () => {
  describe('isExperimentEnabled', () => {
    it.each`
      experiments              | value
      ${{ [TEST_KEY]: true }}  | ${true}
      ${{ [TEST_KEY]: false }} | ${false}
      ${{ def: true }}         | ${false}
      ${{}}                    | ${false}
      ${null}                  | ${false}
    `('returns correct value of $value for experiments=$experiments', ({ experiments, value }) => {
      window.gon = { experiments };

      expect(experimentUtils.isExperimentEnabled(TEST_KEY)).toEqual(value);
    });
  });
});
