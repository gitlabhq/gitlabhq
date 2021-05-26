import {
  decorateEvents,
  decorateData,
  transformStagesForPathNavigation,
  timeSummaryForPathNavigation,
  medianTimeToParsedSeconds,
  formatMedianValues,
} from '~/cycle_analytics/utils';
import {
  selectedStage,
  rawData,
  convertedData,
  rawEvents,
  allowedStages,
  stageMediansWithNumericIds,
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

    it('returns the stages data', () => {
      expect(result.stages).toEqual(convertedData.stages);
    });

    it('returns each of the default value stream stages', () => {
      const stages = result.stages.map(({ name }) => name);
      ['issue', 'plan', 'code', 'test', 'review', 'staging'].forEach((stageName) => {
        expect(stages).toContain(stageName);
      });
    });

    it('returns `-` for summary data that has no value', () => {
      const singleSummaryResult = decorateData({
        stats: [],
        permissions: { issue: true },
        summary: [{ value: null, title: 'Commits' }],
      });
      expect(singleSummaryResult.summary).toEqual([{ value: '-', title: 'Commits' }]);
    });

    it('returns additional fields for each stage', () => {
      const singleStageResult = decorateData({
        stats: [{ name: 'issue', value: null }],
        permissions: { issue: false },
      });
      const stage = singleStageResult.stages[0];
      const txt =
        'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.';

      expect(stage).toMatchObject({
        active: false,
        isUserAllowed: false,
        emptyStageText: txt,
        slug: 'issue',
        component: 'stage-issue-component',
      });
    });
  });

  describe('transformStagesForPathNavigation', () => {
    const stages = allowedStages;
    const response = transformStagesForPathNavigation({
      stages,
      medians: stageMediansWithNumericIds,
      selectedStage,
    });

    describe('transforms the data as expected', () => {
      it('returns an array of stages', () => {
        expect(Array.isArray(response)).toBe(true);
        expect(response.length).toEqual(stages.length);
      });

      it('selects the correct stage', () => {
        const selected = response.filter((stage) => stage.selected === true)[0];

        expect(selected.title).toEqual(selectedStage.title);
      });

      it('includes the correct metric for the associated stage', () => {
        const issue = response.filter((stage) => stage.name === 'issue')[0];

        expect(issue.metric).toEqual(pathNavIssueMetric);
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
      expect(timeSummaryForPathNavigation({ [unit]: value })).toEqual(result);
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
      expect(medianTimeToParsedSeconds(value)).toEqual(result);
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
});
