import { GlSingleStat } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatPresenter from '~/glql/components/presenters/stat.vue';

const TOTAL_COUNT = {
  key: 'totalCount',
  label: 'Total Suggestions',
  name: 'totalCount',
  type: 'metric',
};
const ACCEPTANCE_RATE = {
  key: 'acceptanceRate',
  label: 'Acceptance Rate',
  name: 'acceptanceRate',
  type: 'metric',
};
const USERS_COUNT = {
  key: 'usersCount',
  label: 'Total unique users',
  name: 'usersCount',
  type: 'metric',
};
const DURATION_QUANTILE = {
  key: 'durationQuantile',
  label: 'p95',
  name: 'durationQuantile',
  type: 'metric',
};
const DIMENSION = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };

const DATA = {
  nodes: [
    {
      totalCount: 1234,
      acceptanceRate: 0.735,
      usersCount: 14614,
      durationQuantile: 3661,
    },
  ],
};

describe('StatPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StatPresenter, {
      propsData: {
        data: DATA,
        fields: [TOTAL_COUNT],
        ...props,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSingleStat = () => wrapper.findComponent(GlSingleStat);
  const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the stat', () => {
      expect(findSingleStat().exists()).toBe(false);
    });
  });

  describe('rendering', () => {
    it('renders GlSingleStat with only the value, leaving the title to the container', () => {
      createComponent();

      expect(findSingleStat().exists()).toBe(true);
      expect(findSingleStat().props('title')).toBe('');
    });

    it.each`
      field                | expectedValue
      ${TOTAL_COUNT}       | ${'1,234'}
      ${ACCEPTANCE_RATE}   | ${'73.5%'}
      ${USERS_COUNT}       | ${'14,614'}
      ${DURATION_QUANTILE} | ${'1h 1m 1s'}
    `('formats the value of $field.key as $expectedValue', ({ field, expectedValue }) => {
      createComponent({ fields: [field] });

      expect(findSingleStat().props('value')).toBe(expectedValue);
    });

    it('formats an aliased metric using the canonical field formatter', () => {
      const aliasedMetric = {
        key: 'p50',
        field: 'durationQuantile',
        label: 'Duration P50',
        type: 'metric',
        parameters: { quantile: 0.5 },
      };
      createComponent({ fields: [aliasedMetric], data: { nodes: [{ p50: 3661 }] } });

      expect(findSingleStat().props('value')).toBe('1h 1m 1s');
    });

    it('renders the raw value for a metric with no registered unit', () => {
      const custom = {
        key: 'somethingCustom',
        label: 'Custom',
        name: 'somethingCustom',
        type: 'metric',
      };
      createComponent({ fields: [custom], data: { nodes: [{ somethingCustom: 1234 }] } });

      expect(findSingleStat().props('value')).toBe('1234');
    });

    it('renders a placeholder when the aggregation returns no node', () => {
      createComponent({ data: { nodes: [] } });

      expect(findSingleStat().props('value')).toBe('—');
    });

    it('renders a placeholder when the metric value is null', () => {
      createComponent({ data: { nodes: [{ totalCount: null }] } });

      expect(findSingleStat().props('value')).toBe('—');
    });

    it('renders a real zero value rather than the no-data placeholder', () => {
      createComponent({ data: { nodes: [{ totalCount: 0 }] } });

      expect(findSingleStat().props('value')).toBe('0');
    });
  });

  describe('defaults derived from the metric', () => {
    it('renders the description registered for the metric in the query source', () => {
      createComponent({ fields: [ACCEPTANCE_RATE], source: 'CodeSuggestions' });

      expect(findSingleStat().props('description')).toBe('Ratio of accepted to shown suggestions.');
    });

    // The same metric name counts a different subject in each data source.
    it.each`
      source               | expected
      ${'CodeSuggestions'} | ${'Total number of suggestions.'}
      ${'MergeRequests'}   | ${'Total number of merge requests.'}
    `('describes totalCount as $expected in $source', ({ source, expected }) => {
      createComponent({ fields: [TOTAL_COUNT], source });

      expect(findSingleStat().props('description')).toBe(expected);
    });

    it('renders no description before the query source is known', () => {
      createComponent({ fields: [ACCEPTANCE_RATE] });

      expect(findSingleStat().props('description')).toBeNull();
    });

    it('takes displayConfig.description over the derived copy', () => {
      createComponent({
        fields: [ACCEPTANCE_RATE],
        source: 'CodeSuggestions',
        displayConfig: { description: 'Suggestions accepted in the last 30 days' },
      });

      expect(findSingleStat().props('description')).toBe(
        'Suggestions accepted in the last 30 days',
      );
    });
  });

  describe('trend', () => {
    const PREVIOUS_DATA = { nodes: [{ totalCount: 1000, durationQuantile: 3000 }] };

    it('renders the change from the previous period as the meta badge', () => {
      createComponent({ source: 'CodeSuggestions', comparisonData: PREVIOUS_DATA });

      expect(findSingleStat().props()).toMatchObject({
        value: '1,234',
        metaText: '23.4% vs prior',
        metaIcon: 'arrow-up',
        metaTooltip: 'Up 23.4% from 1,000 in the previous period',
        variant: 'success',
      });
    });

    it('colours a move against the metric direction as danger', () => {
      createComponent({
        fields: [DURATION_QUANTILE],
        source: 'Pipelines',
        comparisonData: PREVIOUS_DATA,
      });

      expect(findSingleStat().props()).toMatchObject({
        value: '1h 1m 1s',
        metaText: '22% vs prior',
        metaIcon: 'arrow-up',
        metaTooltip: 'Up 22% from 50m in the previous period',
        variant: 'danger',
      });
    });

    it('renders a neutral new badge when the previous period is 0', () => {
      createComponent({
        source: 'CodeSuggestions',
        comparisonData: { nodes: [{ totalCount: 0 }] },
      });

      expect(findSingleStat().props()).toMatchObject({
        metaText: 'New',
        metaIcon: 'arrow-up',
        metaTooltip: 'Up from 0 in the previous period',
        variant: 'neutral',
      });
    });

    it('renders no badge without previous period data', () => {
      createComponent({ source: 'CodeSuggestions' });

      expect(findSingleStat().props()).toMatchObject({ metaText: null, metaIcon: null });
    });

    it('renders no badge when the previous period has no row', () => {
      createComponent({ source: 'CodeSuggestions', comparisonData: { nodes: [] } });

      expect(findSingleStat().props()).toMatchObject({ metaText: null, metaIcon: null });
    });

    it('keeps the trend when the block sets only keys outside the badge', () => {
      createComponent({
        source: 'CodeSuggestions',
        comparisonData: PREVIOUS_DATA,
        displayConfig: { title: 'Suggestions', description: 'Shown in the last 30 days' },
      });

      expect(findSingleStat().props()).toMatchObject({
        title: 'Suggestions',
        description: 'Shown in the last 30 days',
        metaText: '23.4% vs prior',
        metaIcon: 'arrow-up',
        variant: 'success',
      });
    });

    // A block's own text under a derived arrow, colour and tooltip would contradict itself.
    it('leaves the whole badge to a block that sets its own metaText', () => {
      createComponent({
        source: 'CodeSuggestions',
        comparisonData: PREVIOUS_DATA,
        displayConfig: { metaText: 'Beta' },
      });

      expect(findSingleStat().props()).toMatchObject({
        metaText: 'Beta',
        metaIcon: null,
        metaTooltip: '',
        variant: 'neutral',
      });
    });

    it.each`
      key              | value
      ${'metaIcon'}    | ${'users'}
      ${'metaTooltip'} | ${'Compared with the previous 30 days'}
      ${'variant'}     | ${'info'}
    `('drops the derived trend when the block sets $key', ({ key, value }) => {
      createComponent({
        source: 'CodeSuggestions',
        comparisonData: PREVIOUS_DATA,
        displayConfig: { [key]: value },
      });

      expect(findSingleStat().props('metaText')).toBeNull();
    });

    it('renders no badge when the block sets metaText to an empty string', () => {
      createComponent({
        source: 'CodeSuggestions',
        comparisonData: PREVIOUS_DATA,
        displayConfig: { metaText: '' },
      });

      expect(findSingleStat().props()).toMatchObject({
        metaText: '',
        metaIcon: null,
        metaTooltip: '',
        variant: 'neutral',
      });
    });
  });

  describe('displayConfig', () => {
    it('leaves every option at its GlSingleStat default when the block sets none', () => {
      createComponent();

      expect(findSingleStat().props()).toMatchObject({
        title: '',
        unit: null,
        description: null,
        metaText: null,
        metaIcon: null,
        metaTooltip: '',
        titleIcon: null,
        variant: 'neutral',
      });
    });

    it.each`
      key              | value
      ${'title'}       | ${'Total suggestions'}
      ${'unit'}        | ${'accepted'}
      ${'description'} | ${'Suggestions shown in the last 30 days'}
      ${'metaText'}    | ${'+140 vs prior'}
      ${'metaIcon'}    | ${'arrow-up'}
      ${'titleIcon'}   | ${'users'}
      ${'variant'}     | ${'success'}
    `('passes $key through to the stat', ({ key, value }) => {
      createComponent({ displayConfig: { [key]: value } });

      expect(findSingleStat().props(key)).toBe(value);
    });

    // GlSingleStat hangs the tooltip off the meta badge, which it only renders with metaText.
    it('passes metaTooltip through to the stat when the block also sets metaText', () => {
      createComponent({
        displayConfig: {
          metaText: '+140 vs prior',
          metaTooltip: 'Compared with the previous 30 days',
        },
      });

      expect(findSingleStat().props('metaTooltip')).toBe('Compared with the previous 30 days');
    });

    it('drops metaTooltip when the block sets no metaText', () => {
      createComponent({ displayConfig: { metaTooltip: 'Compared with the previous 30 days' } });

      expect(findSingleStat().props('metaTooltip')).toBe('');
    });

    it('coerces a value that YAML parsed as a number', () => {
      createComponent({ displayConfig: { title: 2026 } });

      expect(findSingleStat().props('title')).toBe('2026');
    });

    it('falls back to the defaults when the block leaves displayConfig empty', () => {
      createComponent({ displayConfig: null });

      expect(findSingleStat().props()).toMatchObject({ title: '', value: '1,234' });
    });

    it('ignores a key the stat does not read', () => {
      createComponent({ displayConfig: { stacked: true } });

      expect(findSingleStat().props()).toMatchObject({ title: '', value: '1,234' });
    });

    // Excluded on purpose: a class prop would let a GLQL block inject arbitrary CSS.
    it('does not let a block set titleIconClass', () => {
      createComponent({ displayConfig: { titleIcon: 'users', titleIconClass: 'gl-text-danger' } });

      expect(findSingleStat().props('titleIconClass')).toBe('');
    });

    describe('validation', () => {
      it.each(['info', 'success', 'warning', 'danger', 'tier'])(
        'accepts the %s variant',
        (variant) => {
          createComponent({ displayConfig: { variant } });

          expect(findSingleStat().props('variant')).toBe(variant);
          expect(wrapper.emitted('error')).toBeUndefined();
        },
      );

      it('emits an error for an unsupported variant', () => {
        createComponent({ displayConfig: { variant: 'nonsense' } });

        expect(findEmittedErrorMessage()).toBe(
          'Unknown variant: `nonsense`. Supported variants are: `neutral`, `info`, `success`, `warning`, `danger`, `tier`.',
        );
        expect(findSingleStat().exists()).toBe(false);
      });

      it.each(['metaIcon', 'titleIcon'])('emits an error naming %s for an unknown icon', (key) => {
        createComponent({ displayConfig: { [key]: 'not-an-icon' } });

        expect(findEmittedErrorMessage()).toBe(`Unknown icon for \`${key}\`: \`not-an-icon\`.`);
        expect(findSingleStat().exists()).toBe(false);
      });

      it('emits the error before the fields are populated', () => {
        createComponent({ fields: [], displayConfig: { metaIcon: 'not-an-icon' } });

        expect(findEmittedErrorMessage()).toBe('Unknown icon for `metaIcon`: `not-an-icon`.');
      });
    });
  });

  describe('validation', () => {
    it('emits an error when there are no metrics', () => {
      createComponent({ fields: [DIMENSION] });

      expect(findEmittedErrorMessage()).toBe('stat display type requires exactly 1 metric');
      expect(findSingleStat().exists()).toBe(false);
    });

    it('emits an error when there is more than one metric', () => {
      createComponent({ fields: [TOTAL_COUNT, ACCEPTANCE_RATE] });

      expect(findEmittedErrorMessage()).toBe('stat display type requires exactly 1 metric');
      expect(findSingleStat().exists()).toBe(false);
    });

    it('emits an error when dimensions are present', () => {
      createComponent({ fields: [DIMENSION, TOTAL_COUNT] });

      expect(findEmittedErrorMessage()).toBe('stat display type cannot have dimensions');
      expect(findSingleStat().exists()).toBe(false);
    });

    it('does not emit an error and does not render the stat before fields are populated', () => {
      createComponent({ fields: [] });

      expect(wrapper.emitted('error')).toBeUndefined();
      expect(findSingleStat().exists()).toBe(false);
    });
  });
});
