import { DEFAULT_VARIANT } from '~/experimentation/constants';
import * as experimentUtils from '~/experimentation/utils';

const TEST_KEY = 'abc';

describe('experiment Utilities', () => {
  const oldGon = window.gon;

  afterEach(() => {
    window.gon = oldGon;
  });

  describe('getExperimentData', () => {
    it.each`
      gon                                         | input         | output
      ${{ experiment: { [TEST_KEY]: '_data_' } }} | ${[TEST_KEY]} | ${'_data_'}
      ${{}}                                       | ${[TEST_KEY]} | ${undefined}
    `('with input=$input and gon=$gon, returns $output', ({ gon, input, output }) => {
      window.gon = gon;

      expect(experimentUtils.getExperimentData(...input)).toEqual(output);
    });
  });

  describe('isExperimentVariant', () => {
    it.each`
      gon                                                             | input                            | output
      ${{ experiment: { [TEST_KEY]: { variant: 'control' } } }}       | ${[TEST_KEY, 'control']}         | ${true}
      ${{ experiment: { [TEST_KEY]: { variant: '_variant_name' } } }} | ${[TEST_KEY, '_variant_name']}   | ${true}
      ${{ experiment: { [TEST_KEY]: { variant: '_variant_name' } } }} | ${[TEST_KEY, '_bogus_name']}     | ${false}
      ${{ experiment: { [TEST_KEY]: { variant: '_variant_name' } } }} | ${['boguskey', '_variant_name']} | ${false}
      ${{}}                                                           | ${[TEST_KEY, '_variant_name']}   | ${false}
    `('with input=$input and gon=$gon, returns $output', ({ gon, input, output }) => {
      window.gon = gon;

      expect(experimentUtils.isExperimentVariant(...input)).toEqual(output);
    });
  });

  describe('getExperimentVariant', () => {
    it.each`
      gon                                                         | input         | output
      ${{ experiment: { [TEST_KEY]: { variant: 'control' } } }}   | ${[TEST_KEY]} | ${'control'}
      ${{ experiment: { [TEST_KEY]: { variant: 'candidate' } } }} | ${[TEST_KEY]} | ${'candidate'}
      ${{}}                                                       | ${[TEST_KEY]} | ${DEFAULT_VARIANT}
    `('with input=$input and gon=$gon, returns $output', ({ gon, input, output }) => {
      window.gon = gon;

      expect(experimentUtils.getExperimentVariant(...input)).toEqual(output);
    });
  });
});
