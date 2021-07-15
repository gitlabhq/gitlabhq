import { useFakeDate } from 'helpers/fake_date';
import {
  decorateEvents,
  decorateData,
  transformStagesForPathNavigation,
  timeSummaryForPathNavigation,
  medianTimeToParsedSeconds,
  formatMedianValues,
  filterStagesByHiddenStatus,
  calculateFormattedDayInPast,
} from '~/cycle_analytics/utils';
import {
  selectedStage,
  rawData,
  convertedData,
  rawEvents,
  allowedStages,
  stageMedians,
  pathNavIssueMetric,
  rawStageMedians,
} from './mock_data';

describe('Value stream analytics utils', () => {
  describe('decorateEvents', () => {
    const [result] = decorateEvents(rawEvents, selectedStage);
    const eventKeys = Object.keys(result);
    const authorKeys = Object.keys(result.author);
    it('will return the same number of events', () => {
      expect(decorateEvents(rawEvents, selectedStage).length).toBe(rawEvents.length);
    });

    it('will set all the required event fields', () => {
      ['totalTime', 'author', 'createdAt', 'shortSha', 'commitUrl'].forEach((key) => {
        expect(eventKeys).toContain(key);
      });
      ['webUrl', 'avatarUrl'].forEach((key) => {
        expect(authorKeys).toContain(key);
      });
    });

    it('will remove unused fields', () => {
      ['total_time', 'created_at', 'short_sha', 'commit_url'].forEach((key) => {
        expect(eventKeys).not.toContain(key);
      });

      ['web_url', 'avatar_url'].forEach((key) => {
        expect(authorKeys).not.toContain(key);
      });
    });
  });

  describe('decorateData', () => {
    const result = decorateData(rawData);
    it('returns the summary data', () => {
      expect(result.summary).toEqual(convertedData.summary);
    });

    it('returns `-` for summary data that has no value', () => {
      const singleSummaryResult = decorateData({
        stats: [],
        permissions: { issue: true },
        summary: [{ value: null, title: 'Commits' }],
      });
      expect(singleSummaryResult.summary).toEqual([{ value: '-', title: 'Commits' }]);
    });
  });

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
});
