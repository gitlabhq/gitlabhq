import { stubExperiments } from 'helpers/experimentation_helper';
import {
  DEFAULT_VARIANT,
  CANDIDATE_VARIANT,
  TRACKING_CONTEXT_SCHEMA,
} from '~/experimentation/constants';
import * as experimentUtils from '~/experimentation/utils';

describe('experiment Utilities', () => {
  const ABC_KEY = 'abc';
  const DEF_KEY = 'def';

  let origGl;

  beforeEach(() => {
    origGl = window.gl;
    window.gon.experiment = {};
    window.gl.experiments = {};
  });

  afterEach(() => {
    window.gl = origGl;
  });

  describe('getExperimentData', () => {
    const ABC_DATA = '_abc_data_';
    const ABC_DATA2 = '_updated_abc_data_';
    const DEF_DATA = '_def_data_';

    describe.each`
      gonData                | glData                  | input        | output
      ${[ABC_KEY, ABC_DATA]} | ${[]}                   | ${[ABC_KEY]} | ${{ experiment: ABC_KEY, variant: ABC_DATA }}
      ${[]}                  | ${[ABC_KEY, ABC_DATA]}  | ${[ABC_KEY]} | ${{ experiment: ABC_KEY, variant: ABC_DATA }}
      ${[ABC_KEY, ABC_DATA]} | ${[DEF_KEY, DEF_DATA]}  | ${[ABC_KEY]} | ${{ experiment: ABC_KEY, variant: ABC_DATA }}
      ${[ABC_KEY, ABC_DATA]} | ${[DEF_KEY, DEF_DATA]}  | ${[DEF_KEY]} | ${{ experiment: DEF_KEY, variant: DEF_DATA }}
      ${[ABC_KEY, ABC_DATA]} | ${[ABC_KEY, ABC_DATA2]} | ${[ABC_KEY]} | ${{ experiment: ABC_KEY, variant: ABC_DATA2 }}
      ${[]}                  | ${[]}                   | ${[ABC_KEY]} | ${undefined}
    `('with input=$input, gon=$gonData, & gl=$glData', ({ gonData, glData, input, output }) => {
      beforeEach(() => {
        const [gonKey, gonVariant] = gonData;
        const [glKey, glVariant] = glData;

        if (gonKey) window.gon.experiment[gonKey] = { experiment: gonKey, variant: gonVariant };
        if (glKey) window.gl.experiments[glKey] = { experiment: glKey, variant: glVariant };
      });

      it(`returns ${output}`, () => {
        expect(experimentUtils.getExperimentData(...input)).toEqual(output);
      });
    });

    it('only collects the data properties which are supported by the schema', () => {
      origGl = window.gl;
      window.gl.experiments = {
        my_experiment: {
          experiment: 'my_experiment',
          variant: 'control',
          key: 'randomization-unit-key',
          migration_keys: 'migration_keys object',
          excluded: false,
          other: 'foobar',
        },
      };

      expect(experimentUtils.getExperimentData('my_experiment')).toEqual({
        experiment: 'my_experiment',
        variant: 'control',
        key: 'randomization-unit-key',
        migration_keys: 'migration_keys object',
      });

      window.gl = origGl;
    });
  });

  describe('getAllExperimentContexts', () => {
    const schema = TRACKING_CONTEXT_SCHEMA;

    it('collects all of the experiment contexts into a single array', () => {
      const experiments = { [ABC_KEY]: 'candidate', [DEF_KEY]: 'control', ghi: 'blue' };

      stubExperiments(experiments);

      expect(experimentUtils.getAllExperimentContexts()).toEqual(
        Object.entries(experiments).map(([experiment, variant]) => ({
          schema,
          data: { experiment, variant },
        })),
      );
    });

    it('returns an empty array if there are no experiments', () => {
      expect(experimentUtils.getAllExperimentContexts()).toEqual([]);
    });
  });

  describe('isExperimentVariant', () => {
    describe.each`
      experiment   | variant              | input                            | output
      ${ABC_KEY}   | ${CANDIDATE_VARIANT} | ${[ABC_KEY]}                     | ${true}
      ${ABC_KEY}   | ${DEFAULT_VARIANT}   | ${[ABC_KEY, DEFAULT_VARIANT]}    | ${true}
      ${ABC_KEY}   | ${'_variant_name'}   | ${[ABC_KEY, '_variant_name']}    | ${true}
      ${ABC_KEY}   | ${'_variant_name'}   | ${[ABC_KEY, '_bogus_name']}      | ${false}
      ${ABC_KEY}   | ${'_variant_name'}   | ${['boguskey', '_variant_name']} | ${false}
      ${undefined} | ${undefined}         | ${[ABC_KEY, '_variant_name']}    | ${false}
    `(
      'with input=$input, experiment=$experiment, variant=$variant',
      ({ experiment, variant, input, output }) => {
        it(`returns ${output}`, () => {
          if (experiment) stubExperiments({ [experiment]: variant });

          expect(experimentUtils.isExperimentVariant(...input)).toEqual(output);
        });
      },
    );
  });

  describe('experiment', () => {
    const experiment = 'marley';
    const useSpy = jest.fn();
    const controlSpy = jest.fn();
    const trySpy = jest.fn();
    const candidateSpy = jest.fn();
    const getUpStandUpSpy = jest.fn();

    const variants = {
      use: useSpy,
      try: trySpy,
      get_up_stand_up: getUpStandUpSpy,
    };

    describe('when there is no experiment data', () => {
      it('calls the use variant', () => {
        experimentUtils.experiment(experiment, variants);
        expect(useSpy).toHaveBeenCalled();
      });

      describe("when 'control' is provided instead of 'use'", () => {
        it('calls the control variant', () => {
          experimentUtils.experiment(experiment, { control: controlSpy });
          expect(controlSpy).toHaveBeenCalled();
        });
      });
    });

    describe('when experiment variant is "control"', () => {
      beforeEach(() => {
        stubExperiments({ [experiment]: DEFAULT_VARIANT });
      });

      it('calls the use variant', () => {
        experimentUtils.experiment(experiment, variants);
        expect(useSpy).toHaveBeenCalled();
      });

      describe("when 'control' is provided instead of 'use'", () => {
        it('calls the control variant', () => {
          experimentUtils.experiment(experiment, { control: controlSpy });
          expect(controlSpy).toHaveBeenCalled();
        });
      });
    });

    describe('when experiment variant is "candidate"', () => {
      beforeEach(() => {
        stubExperiments({ [experiment]: CANDIDATE_VARIANT });
      });

      it('calls the try variant', () => {
        experimentUtils.experiment(experiment, variants);
        expect(trySpy).toHaveBeenCalled();
      });

      describe("when 'candidate' is provided instead of 'try'", () => {
        it('calls the candidate variant', () => {
          experimentUtils.experiment(experiment, { candidate: candidateSpy });
          expect(candidateSpy).toHaveBeenCalled();
        });
      });
    });

    describe('when experiment variant is "get_up_stand_up"', () => {
      beforeEach(() => {
        stubExperiments({ [experiment]: 'get_up_stand_up' });
      });

      it('calls the get-up-stand-up variant', () => {
        experimentUtils.experiment(experiment, variants);
        expect(getUpStandUpSpy).toHaveBeenCalled();
      });
    });
  });

  describe('getExperimentVariant', () => {
    it.each`
      experiment   | variant              | input      | output
      ${ABC_KEY}   | ${DEFAULT_VARIANT}   | ${ABC_KEY} | ${DEFAULT_VARIANT}
      ${ABC_KEY}   | ${CANDIDATE_VARIANT} | ${ABC_KEY} | ${CANDIDATE_VARIANT}
      ${undefined} | ${undefined}         | ${ABC_KEY} | ${DEFAULT_VARIANT}
    `(
      'with input=$input, experiment=$experiment, & variant=$variant; returns $output',
      ({ experiment, variant, input, output }) => {
        stubExperiments({ [experiment]: variant });

        expect(experimentUtils.getExperimentVariant(input)).toEqual(output);
      },
    );
  });
});
