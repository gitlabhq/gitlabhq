import { assignGitlabExperiment } from 'helpers/experimentation_helper';
import {
  DEFAULT_VARIANT,
  CANDIDATE_VARIANT,
  TRACKING_CONTEXT_SCHEMA,
} from '~/experimentation/constants';
import * as experimentUtils from '~/experimentation/utils';

describe('experiment Utilities', () => {
  const TEST_KEY = 'abc';

  describe('getExperimentData', () => {
    describe.each`
      gon                     | input         | output
      ${[TEST_KEY, '_data_']} | ${[TEST_KEY]} | ${{ variant: '_data_' }}
      ${[]}                   | ${[TEST_KEY]} | ${undefined}
    `('with input=$input and gon=$gon', ({ gon, input, output }) => {
      assignGitlabExperiment(...gon);

      it(`returns ${output}`, () => {
        expect(experimentUtils.getExperimentData(...input)).toEqual(output);
      });
    });
  });

  describe('getExperimentContexts', () => {
    describe.each`
      gon                     | input         | output
      ${[TEST_KEY, '_data_']} | ${[TEST_KEY]} | ${[{ schema: TRACKING_CONTEXT_SCHEMA, data: { variant: '_data_' } }]}
      ${[]}                   | ${[TEST_KEY]} | ${[]}
    `('with input=$input and gon=$gon', ({ gon, input, output }) => {
      assignGitlabExperiment(...gon);

      it(`returns ${output}`, () => {
        expect(experimentUtils.getExperimentContexts(...input)).toEqual(output);
      });
    });
  });

  describe('isExperimentVariant', () => {
    describe.each`
      gon                            | input                            | output
      ${[TEST_KEY, DEFAULT_VARIANT]} | ${[TEST_KEY, DEFAULT_VARIANT]}   | ${true}
      ${[TEST_KEY, '_variant_name']} | ${[TEST_KEY, '_variant_name']}   | ${true}
      ${[TEST_KEY, '_variant_name']} | ${[TEST_KEY, '_bogus_name']}     | ${false}
      ${[TEST_KEY, '_variant_name']} | ${['boguskey', '_variant_name']} | ${false}
      ${[]}                          | ${[TEST_KEY, '_variant_name']}   | ${false}
    `('with input=$input and gon=$gon', ({ gon, input, output }) => {
      assignGitlabExperiment(...gon);

      it(`returns ${output}`, () => {
        expect(experimentUtils.isExperimentVariant(...input)).toEqual(output);
      });
    });
  });

  describe('experiment', () => {
    const controlSpy = jest.fn();
    const candidateSpy = jest.fn();
    const getUpStandUpSpy = jest.fn();

    const variants = {
      use: controlSpy,
      try: candidateSpy,
      get_up_stand_up: getUpStandUpSpy,
    };

    describe('when there is no experiment data', () => {
      it('calls control variant', () => {
        experimentUtils.experiment('marley', variants);
        expect(controlSpy).toHaveBeenCalled();
      });
    });

    describe('when experiment variant is "control"', () => {
      assignGitlabExperiment('marley', DEFAULT_VARIANT);

      it('calls the control variant', () => {
        experimentUtils.experiment('marley', variants);
        expect(controlSpy).toHaveBeenCalled();
      });
    });

    describe('when experiment variant is "candidate"', () => {
      assignGitlabExperiment('marley', CANDIDATE_VARIANT);

      it('calls the candidate variant', () => {
        experimentUtils.experiment('marley', variants);
        expect(candidateSpy).toHaveBeenCalled();
      });
    });

    describe('when experiment variant is "get_up_stand_up"', () => {
      assignGitlabExperiment('marley', 'get_up_stand_up');

      it('calls the get-up-stand-up variant', () => {
        experimentUtils.experiment('marley', variants);
        expect(getUpStandUpSpy).toHaveBeenCalled();
      });
    });
  });

  describe('getExperimentVariant', () => {
    it.each`
      gon                                                               | input         | output
      ${{ experiment: { [TEST_KEY]: { variant: DEFAULT_VARIANT } } }}   | ${[TEST_KEY]} | ${DEFAULT_VARIANT}
      ${{ experiment: { [TEST_KEY]: { variant: CANDIDATE_VARIANT } } }} | ${[TEST_KEY]} | ${CANDIDATE_VARIANT}
      ${{}}                                                             | ${[TEST_KEY]} | ${DEFAULT_VARIANT}
    `('with input=$input and gon=$gon, returns $output', ({ gon, input, output }) => {
      window.gon = gon;

      expect(experimentUtils.getExperimentVariant(...input)).toEqual(output);
    });
  });
});
