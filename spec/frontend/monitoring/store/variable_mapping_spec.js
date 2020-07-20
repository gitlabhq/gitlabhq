import {
  parseTemplatingVariables,
  mergeURLVariables,
  optionsFromSeriesData,
} from '~/monitoring/stores/variable_mapping';
import {
  templatingVariablesExamples,
  storeTextVariables,
  storeCustomVariables,
  storeMetricLabelValuesVariables,
} from '../mock_data';
import * as urlUtils from '~/lib/utils/url_utility';

describe('Monitoring variable mapping', () => {
  describe('parseTemplatingVariables', () => {
    it.each`
      case                                 | input
      ${'For undefined templating object'} | ${undefined}
      ${'For empty templating object'}     | ${{}}
    `('$case, returns an empty array', ({ input }) => {
      expect(parseTemplatingVariables(input)).toEqual([]);
    });

    it.each`
      case                                                        | input                                            | output
      ${'Returns parsed object for text variables'}               | ${templatingVariablesExamples.text}              | ${storeTextVariables}
      ${'Returns parsed object for custom variables'}             | ${templatingVariablesExamples.custom}            | ${storeCustomVariables}
      ${'Returns parsed object for metric label value variables'} | ${templatingVariablesExamples.metricLabelValues} | ${storeMetricLabelValuesVariables}
    `('$case, returns an empty array', ({ input, output }) => {
      expect(parseTemplatingVariables(input)).toEqual(output);
    });
  });

  describe('mergeURLVariables', () => {
    beforeEach(() => {
      jest.spyOn(urlUtils, 'queryToObject');
    });

    afterEach(() => {
      urlUtils.queryToObject.mockRestore();
    });

    it('returns empty object if variables are not defined in yml or URL', () => {
      urlUtils.queryToObject.mockReturnValueOnce({});

      expect(mergeURLVariables([])).toEqual([]);
    });

    it('returns empty object if variables are defined in URL but not in yml', () => {
      urlUtils.queryToObject.mockReturnValueOnce({
        'var-env': 'one',
        'var-instance': 'localhost',
      });

      expect(mergeURLVariables([])).toEqual([]);
    });

    it('returns yml variables if variables defined in yml but not in the URL', () => {
      urlUtils.queryToObject.mockReturnValueOnce({});

      const variables = [
        {
          name: 'env',
          value: 'one',
        },
        {
          name: 'instance',
          value: 'localhost',
        },
      ];

      expect(mergeURLVariables(variables)).toEqual(variables);
    });

    it('returns yml variables if variables defined in URL do not match with yml variables', () => {
      const urlParams = {
        'var-env': 'one',
        'var-instance': 'localhost',
      };
      const variables = [
        {
          name: 'env',
          value: 'one',
        },
        {
          name: 'service',
          value: 'database',
        },
      ];
      urlUtils.queryToObject.mockReturnValueOnce(urlParams);

      expect(mergeURLVariables(variables)).toEqual(variables);
    });

    it('returns merged yml and URL variables if there is some match', () => {
      const urlParams = {
        'var-env': 'one',
        'var-instance': 'localhost:8080',
      };
      const variables = [
        {
          name: 'instance',
          value: 'localhost',
        },
        {
          name: 'service',
          value: 'database',
        },
      ];

      urlUtils.queryToObject.mockReturnValueOnce(urlParams);

      expect(mergeURLVariables(variables)).toEqual([
        {
          name: 'instance',
          value: 'localhost:8080',
        },
        {
          name: 'service',
          value: 'database',
        },
      ]);
    });
  });

  describe('optionsFromSeriesData', () => {
    it('fetches the label values from missing data', () => {
      expect(optionsFromSeriesData({ label: 'job' })).toEqual([]);
    });

    it('fetches the label values from a simple series', () => {
      const data = [
        {
          __name__: 'up',
          job: 'job1',
        },
        {
          __name__: 'up',
          job: 'job2',
        },
      ];

      expect(optionsFromSeriesData({ label: 'job', data })).toEqual([
        { text: 'job1', value: 'job1' },
        { text: 'job2', value: 'job2' },
      ]);
    });

    it('fetches the label values from multiple series', () => {
      const data = [
        {
          __name__: 'up',
          job: 'job1',
          instance: 'host1',
        },
        {
          __name__: 'up',
          job: 'job2',
          instance: 'host1',
        },
        {
          __name__: 'up',
          job: 'job1',
          instance: 'host2',
        },
        {
          __name__: 'up',
          job: 'job2',
          instance: 'host2',
        },
      ];

      expect(optionsFromSeriesData({ label: '__name__', data })).toEqual([
        { text: 'up', value: 'up' },
      ]);

      expect(optionsFromSeriesData({ label: 'job', data })).toEqual([
        { text: 'job1', value: 'job1' },
        { text: 'job2', value: 'job2' },
      ]);

      expect(optionsFromSeriesData({ label: 'instance', data })).toEqual([
        { text: 'host1', value: 'host1' },
        { text: 'host2', value: 'host2' },
      ]);
    });

    it('fetches the label values from a series with missing values', () => {
      const data = [
        {
          __name__: 'up',
          job: 'job1',
        },
        {
          __name__: 'up',
          job: 'job2',
        },
        {
          __name__: 'up',
        },
      ];

      expect(optionsFromSeriesData({ label: 'job', data })).toEqual([
        { text: 'job1', value: 'job1' },
        { text: 'job2', value: 'job2' },
      ]);
    });
  });
});
