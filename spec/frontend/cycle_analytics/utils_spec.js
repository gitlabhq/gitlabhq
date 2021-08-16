import { useFakeDate } from 'helpers/fake_date';
import {
  transformStagesForPathNavigation,
  timeSummaryForPathNavigation,
  medianTimeToParsedSeconds,
  formatMedianValues,
  filterStagesByHiddenStatus,
  calculateFormattedDayInPast,
  prepareTimeMetricsData,
} from '~/cycle_analytics/utils';
import { slugify } from '~/lib/utils/text_utility';
import {
  selectedStage,
  allowedStages,
  stageMedians,
  pathNavIssueMetric,
  rawStageMedians,
  metricsData,
} from './mock_data';

describe('Value stream analytics utils', () => {
  describe('transformStagesForPathNavigation', () => {
    const stages = allowedStages;
    const response = transformStagesForPathNavigation({
      stages,
      medians: stageMedians,
      selectedStage,
    });

    describe('transforms the data as expected', () => {
      it('returns an array of stages', () => {
        expect(Array.isArray(response)).toBe(true);
        expect(response.length).toBe(stages.length);
      });

      it('selects the correct stage', () => {
        const selected = response.filter((stage) => stage.selected === true)[0];

        expect(selected.title).toBe(selectedStage.title);
      });

      it('includes the correct metric for the associated stage', () => {
        const issue = response.filter((stage) => stage.name === 'issue')[0];

        expect(issue.metric).toBe(pathNavIssueMetric);
      });
    });
  });

  describe('timeSummaryForPathNavigation', () => {
    it.each`
      unit         | value   | result
      ${'months'}  | ${1.5}  | ${'1.5M'}
      ${'weeks'}   | ${1.25} | ${'1.5w'}
      ${'days'}    | ${2}    | ${'2d'}
      ${'hours'}   | ${10}   | ${'10h'}
      ${'minutes'} | ${20}   | ${'20m'}
      ${'seconds'} | ${10}   | ${'<1m'}
      ${'seconds'} | ${0}    | ${'-'}
    `('will format $value $unit to $result', ({ unit, value, result }) => {
      expect(timeSummaryForPathNavigation({ [unit]: value })).toBe(result);
    });
  });

  describe('medianTimeToParsedSeconds', () => {
    it.each`
      value      | result
      ${1036800} | ${'1w'}
      ${259200}  | ${'3d'}
      ${172800}  | ${'2d'}
      ${86400}   | ${'1d'}
      ${1000}    | ${'16m'}
      ${61}      | ${'1m'}
      ${59}      | ${'<1m'}
      ${0}       | ${'-'}
    `('will correctly parse $value seconds into $result', ({ value, result }) => {
      expect(medianTimeToParsedSeconds(value)).toBe(result);
    });
  });

  describe('formatMedianValues', () => {
    const calculatedMedians = formatMedianValues(rawStageMedians);

    it('returns an object with each stage and their median formatted for display', () => {
      rawStageMedians.forEach(({ id, value }) => {
        expect(calculatedMedians).toMatchObject({ [id]: medianTimeToParsedSeconds(value) });
      });
    });
  });

  describe('filterStagesByHiddenStatus', () => {
    const hiddenStages = [{ title: 'three', hidden: true }];
    const visibleStages = [
      { title: 'one', hidden: false },
      { title: 'two', hidden: false },
    ];
    const mockStages = [...visibleStages, ...hiddenStages];

    it.each`
      isHidden     | result
      ${false}     | ${visibleStages}
      ${undefined} | ${hiddenStages}
      ${true}      | ${hiddenStages}
    `('with isHidden=$isHidden returns matching stages', ({ isHidden, result }) => {
      expect(filterStagesByHiddenStatus(mockStages, isHidden)).toEqual(result);
    });
  });

  describe('calculateFormattedDayInPast', () => {
    useFakeDate(1815, 11, 10);

    it('will return 2 dates, now and past', () => {
      expect(calculateFormattedDayInPast(5)).toEqual({ now: '1815-12-10', past: '1815-12-05' });
    });
  });

  describe('prepareTimeMetricsData', () => {
    let prepared;
    const [first, second] = metricsData;
    const firstKey = slugify(first.title);
    const secondKey = slugify(second.title);

    beforeEach(() => {
      prepared = prepareTimeMetricsData([first, second], {
        [firstKey]: { description: 'Is a value that is good' },
      });
    });

    it('will add a `key` based on the title', () => {
      expect(prepared).toMatchObject([{ key: firstKey }, { key: secondKey }]);
    });

    it('will add a `label` key', () => {
      expect(prepared).toMatchObject([{ label: 'New Issues' }, { label: 'Commits' }]);
    });

    it('will add a popover description using the key if it is provided', () => {
      expect(prepared).toMatchObject([
        { description: 'Is a value that is good' },
        { description: '' },
      ]);
    });
  });
});
