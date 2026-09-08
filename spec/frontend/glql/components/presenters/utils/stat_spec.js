import {
  positiveDirectionFor,
  statPresentationFor,
  trendPresentationFor,
} from '~/glql/components/presenters/utils/stat';

const metric = (key, extra = {}) => ({ key, name: key, label: key, type: 'metric', ...extra });

const DEFAULTS = {
  title: '',
  unit: null,
  description: null,
  metaText: null,
  metaIcon: null,
  metaTooltip: '',
  titleIcon: null,
  variant: 'neutral',
};

describe('statPresentationFor', () => {
  describe('defaults derived from the metric', () => {
    it.each`
      source               | fieldKey                 | expected
      ${'CodeSuggestions'} | ${'acceptanceRate'}      | ${'Ratio of accepted to shown suggestions.'}
      ${'CodeSuggestions'} | ${'acceptedCount'}       | ${'Number of accepted suggestions.'}
      ${'AiUsageEvents'}   | ${'featuresCount'}       | ${'Number of unique features used.'}
      ${'Pipelines'}       | ${'failureRate'}         | ${'Ratio of failed pipelines to finished pipelines.'}
      ${'Pipelines'}       | ${'durationQuantile'}    | ${'Pipeline duration quantile, in seconds.'}
      ${'MergeRequests'}   | ${'timeToMergeQuantile'} | ${'Time from creation to merge.'}
      ${'Contributions'}   | ${'usersCount'}          | ${'Number of unique contributors.'}
    `('derives the description of $fieldKey in $source', ({ source, fieldKey, expected }) => {
      expect(statPresentationFor(source, metric(fieldKey)).description).toBe(expected);
    });

    // The reason the map is keyed by data source: one metric name, a different subject
    // in each source.
    it.each`
      source               | expected
      ${'CodeSuggestions'} | ${'Total number of suggestions.'}
      ${'AiUsageEvents'}   | ${'Total number of events.'}
      ${'Pipelines'}       | ${'Total number of pipelines, including in-progress ones.'}
      ${'MergeRequests'}   | ${'Total number of merge requests.'}
      ${'Contributions'}   | ${'Total number of contributions.'}
    `('describes totalCount as $expected in $source', ({ source, expected }) => {
      expect(statPresentationFor(source, metric('totalCount')).description).toBe(expected);
    });

    it('derives the description of an aliased metric from its base field key', () => {
      const aliased = metric('p50', { field: 'durationQuantile', parameters: { quantile: 0.5 } });

      expect(statPresentationFor('Pipelines', aliased).description).toBe(
        'Pipeline duration quantile, in seconds.',
      );
    });

    it('has no derived description for a metric another source registers', () => {
      expect(statPresentationFor('Pipelines', metric('acceptanceRate')).description).toBeNull();
    });

    it.each([undefined, '', 'SomethingCustom'])(
      'has no derived description when the source is %p',
      (source) => {
        expect(statPresentationFor(source, metric('totalCount')).description).toBeNull();
      },
    );

    it('has no derived description for an unregistered metric', () => {
      expect(
        statPresentationFor('CodeSuggestions', metric('somethingCustom')).description,
      ).toBeNull();
    });

    it('leaves every prop other than the description to the container or the config', () => {
      expect(statPresentationFor('CodeSuggestions', metric('somethingCustom'))).toEqual(DEFAULTS);
    });

    it('returns the defaults when there is no metric yet', () => {
      expect(statPresentationFor('CodeSuggestions', undefined)).toEqual(DEFAULTS);
    });

    it.each([undefined, null])('returns the defaults when displayConfig is %p', (displayConfig) => {
      expect(
        statPresentationFor('CodeSuggestions', metric('somethingCustom'), displayConfig),
      ).toEqual(DEFAULTS);
    });
  });

  describe('displayConfig overrides', () => {
    it.each`
      key              | value
      ${'title'}       | ${'DAP users'}
      ${'unit'}        | ${'resolved'}
      ${'description'} | ${'Users with a Duo seat'}
      ${'metaText'}    | ${'+140 vs prior'}
      ${'metaIcon'}    | ${'arrow-up'}
      ${'titleIcon'}   | ${'users'}
      ${'variant'}     | ${'success'}
    `('lets displayConfig.$key override the default', ({ key, value }) => {
      expect(
        statPresentationFor('CodeSuggestions', metric('totalCount'), { [key]: value }),
      ).toMatchObject({
        [key]: value,
      });
    });

    // GlSingleStat hangs the tooltip off the meta badge, which it only renders with metaText.
    it('keeps metaTooltip when the block also sets metaText', () => {
      const presentation = statPresentationFor('CodeSuggestions', metric('totalCount'), {
        metaText: '+140 vs prior',
        metaTooltip: 'Compared with the previous 30 days',
      });

      expect(presentation.metaTooltip).toBe('Compared with the previous 30 days');
    });

    it('drops metaTooltip when the block sets no metaText', () => {
      const presentation = statPresentationFor('CodeSuggestions', metric('totalCount'), {
        metaTooltip: 'Compared with the previous 30 days',
      });

      expect(presentation.metaTooltip).toBe('');
    });

    it('takes an explicit description over the derived copy', () => {
      const presentation = statPresentationFor('CodeSuggestions', metric('acceptanceRate'), {
        description: 'Custom copy',
      });

      expect(presentation.description).toBe('Custom copy');
    });

    it('suppresses the derived description when the override is empty', () => {
      const presentation = statPresentationFor('CodeSuggestions', metric('acceptanceRate'), {
        description: '',
      });

      expect(presentation.description).toBe('');
    });

    it('coerces a value that YAML parsed as a number', () => {
      expect(
        statPresentationFor('CodeSuggestions', metric('totalCount'), { title: 2026 }).title,
      ).toBe('2026');
    });

    // Returned as authored so the presenter can reject it as a GLQL block error rather
    // than silently rendering a stat the block did not ask for.
    it('returns an unsupported variant unchanged', () => {
      expect(
        statPresentationFor('CodeSuggestions', metric('totalCount'), { variant: 'nonsense' })
          .variant,
      ).toBe('nonsense');
    });
  });
});

describe('trendPresentationFor', () => {
  it.each`
    source               | fieldKey              | value    | previousValue | expected
    ${'CodeSuggestions'} | ${'totalCount'}       | ${120}   | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 100 in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${80}    | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-down', metaTooltip: 'Down 20% from 100 in the previous period', variant: 'danger' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${100}   | ${100}        | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 100 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${0}     | ${100}        | ${{ metaText: '100% vs prior', metaIcon: 'arrow-down', metaTooltip: 'Down 100% from 100 in the previous period', variant: 'danger' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${0}     | ${0}          | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 0 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${120}   | ${0}          | ${{ metaText: 'New', metaIcon: 'arrow-up', metaTooltip: 'Up from 0 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'acceptanceRate'}   | ${0.6}   | ${0}          | ${{ metaText: 'New', metaIcon: 'arrow-up', metaTooltip: 'Up from 0% in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'rejectedCount'}    | ${120}   | ${0}          | ${{ metaText: 'New', metaIcon: 'arrow-up', metaTooltip: 'Up from 0 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${1234}  | ${1000}       | ${{ metaText: '23.4% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 23.4% from 1,000 in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${10004} | ${10000}      | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 10,000 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${9996}  | ${10000}      | ${{ metaText: '0% vs prior', metaIcon: null, metaTooltip: 'No change from 10,000 in the previous period', variant: 'neutral' }}
    ${'CodeSuggestions'} | ${'totalCount'}       | ${10006} | ${10000}      | ${{ metaText: '0.1% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 0.1% from 10,000 in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'acceptanceRate'}   | ${0.6}   | ${0.5}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 50% in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'rejectedCount'}    | ${120}   | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 100 in the previous period', variant: 'danger' }}
    ${'Pipelines'}       | ${'durationQuantile'} | ${90}    | ${120}        | ${{ metaText: '25% vs prior', metaIcon: 'arrow-down', metaTooltip: 'Down 25% from 2m in the previous period', variant: 'success' }}
    ${'CodeSuggestions'} | ${'somethingCustom'}  | ${120}   | ${100}        | ${{ metaText: '20% vs prior', metaIcon: 'arrow-up', metaTooltip: 'Up 20% from 100 in the previous period', variant: 'neutral' }}
  `(
    'describes $fieldKey moving from $previousValue to $value in $source',
    ({ source, fieldKey, value, previousValue, expected }) => {
      expect(trendPresentationFor(source, metric(fieldKey), { value, previousValue })).toEqual(
        expected,
      );
    },
  );

  it('colours through the base field key of an aliased metric', () => {
    const aliased = metric('p50', { field: 'durationQuantile', parameters: { quantile: 0.5 } });

    expect(
      trendPresentationFor('Pipelines', aliased, { value: 90, previousValue: 120 }),
    ).toMatchObject({
      metaTooltip: 'Down 25% from 2m in the previous period',
      variant: 'success',
    });
  });

  it.each`
    value        | previousValue
    ${120}       | ${null}
    ${120}       | ${undefined}
    ${null}      | ${100}
    ${undefined} | ${100}
  `('has no trend for $value against $previousValue', ({ value, previousValue }) => {
    expect(
      trendPresentationFor('CodeSuggestions', metric('totalCount'), { value, previousValue }),
    ).toBeNull();
  });
});

describe('positiveDirectionFor', () => {
  it.each`
    source               | fieldKey                 | expected
    ${'CodeSuggestions'} | ${'totalCount'}          | ${'up'}
    ${'CodeSuggestions'} | ${'acceptanceRate'}      | ${'up'}
    ${'CodeSuggestions'} | ${'rejectedCount'}       | ${'down'}
    ${'Pipelines'}       | ${'successRate'}         | ${'up'}
    ${'Pipelines'}       | ${'failureRate'}         | ${'down'}
    ${'Pipelines'}       | ${'durationQuantile'}    | ${'down'}
    ${'MergeRequests'}   | ${'timeToMergeQuantile'} | ${'down'}
    ${'CodeSuggestions'} | ${'somethingCustom'}     | ${null}
  `('returns $expected for $fieldKey in $source', ({ source, fieldKey, expected }) => {
    expect(positiveDirectionFor(source, metric(fieldKey))).toBe(expected);
  });

  it('falls back to the unit default when the source registers no override', () => {
    expect(positiveDirectionFor('MergeRequests', metric('rejectedCount'))).toBe('up');
  });

  it('resolves through the base field key of an aliased metric', () => {
    expect(positiveDirectionFor('Pipelines', metric('p50', { field: 'durationQuantile' }))).toBe(
      'down',
    );
  });
});
