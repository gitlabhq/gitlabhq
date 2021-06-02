import { unescape } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { roundToNearestHalf, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { parseSeconds } from '~/lib/utils/datetime_utility';
import { dasherize } from '~/lib/utils/text_utility';
import { __, s__, sprintf } from '../locale';
import DEFAULT_EVENT_OBJECTS from './default_event_objects';

const EMPTY_STAGE_TEXTS = {
  issue: __(
    'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.',
  ),
  plan: __(
    'The planning stage shows the time from the previous step to pushing your first commit. This time will be added automatically once you push your first commit.',
  ),
  code: __(
    'The coding stage shows the time from the first commit to creating the merge request. The data will automatically be added here once you create your first merge request.',
  ),
  test: __(
    'The testing stage shows the time GitLab CI takes to run every pipeline for the related merge request. The data will automatically be added after your first pipeline finishes running.',
  ),
  review: __(
    'The review stage shows the time from creating the merge request to merging it. The data will automatically be added after you merge your first merge request.',
  ),
  staging: __(
    'The staging stage shows the time between merging the MR and deploying code to the production environment. The data will be automatically added once you deploy to production for the first time.',
  ),
};

/**
 * These `decorate` methods will be removed when me migrate to the
 * new table layout https://gitlab.com/gitlab-org/gitlab/-/issues/326704
 */
const mapToEvent = (event, stage) => {
  return convertObjectPropsToCamelCase(
    {
      ...DEFAULT_EVENT_OBJECTS[stage.slug],
      ...event,
    },
    { deep: true },
  );
};

export const decorateEvents = (events, stage) => events.map((event) => mapToEvent(event, stage));

/*
 * NOTE: We currently use the `name` field since the project level stages are in memory
 * once we migrate to a default value stream https://gitlab.com/gitlab-org/gitlab/-/issues/326705
 * we can use the `id` to identify which median we are using
 */
const mapToStage = (permissions, { name, ...rest }) => {
  const slug = dasherize(name.toLowerCase());
  return {
    ...rest,
    name,
    id: name,
    slug,
    active: false,
    isUserAllowed: permissions[slug],
    emptyStageText: EMPTY_STAGE_TEXTS[slug],
    component: `stage-${slug}-component`,
  };
};

const mapToSummary = ({ value, ...rest }) => ({ ...rest, value: value || '-' });
const mapToMedians = ({ id, value }) => ({ id, value });

export const decorateData = (data = {}) => {
  const { permissions, stats, summary } = data;
  const stages = stats?.map((item) => mapToStage(permissions, item)) || [];
  return {
    stages,
    summary: summary?.map((item) => mapToSummary(item)) || [],
    medians: stages?.map((item) => mapToMedians(item)) || [],
  };
};

/**
 * Takes the stages and median data, combined with the selected stage, to build an
 * array which is formatted to proivde the data required for the path navigation.
 *
 * @param {Array} stages - The stages available to the group / project
 * @param {Object} medians - The median values for the stages available to the group / project
 * @param {Object} stageCounts - The total item count for the stages available
 * @param {Object} selectedStage - The currently selected stage
 * @returns {Array} An array of stages formatted with data required for the path navigation
 */
export const transformStagesForPathNavigation = ({
  stages,
  medians,
  stageCounts = {},
  selectedStage,
}) => {
  const formattedStages = stages.map((stage) => {
    return {
      metric: medians[stage?.id],
      selected: stage?.id === selectedStage?.id, // Also could null === null cause an issue here?
      stageCount: stageCounts && stageCounts[stage?.id],
      icon: null,
      ...stage,
    };
  });

  return formattedStages;
};

export const timeSummaryForPathNavigation = ({ seconds, hours, days, minutes, weeks, months }) => {
  if (months) {
    return sprintf(s__('ValueStreamAnalytics|%{value}M'), {
      value: roundToNearestHalf(months),
    });
  } else if (weeks) {
    return sprintf(s__('ValueStreamAnalytics|%{value}w'), {
      value: roundToNearestHalf(weeks),
    });
  } else if (days) {
    return sprintf(s__('ValueStreamAnalytics|%{value}d'), {
      value: roundToNearestHalf(days),
    });
  } else if (hours) {
    return sprintf(s__('ValueStreamAnalytics|%{value}h'), { value: hours });
  } else if (minutes) {
    return sprintf(s__('ValueStreamAnalytics|%{value}m'), { value: minutes });
  } else if (seconds) {
    return unescape(sanitize(s__('ValueStreamAnalytics|&lt;1m'), { ALLOWED_TAGS: [] }));
  }
  return '-';
};

/**
 * Takes a raw median value in seconds and converts it to a string representation
 * ie. converts 172800 => 2d (2 days)
 *
 * @param {Number} Median - The number of seconds for the median calculation
 * @returns {String} String representation ie 2w
 */
export const medianTimeToParsedSeconds = (value) =>
  timeSummaryForPathNavigation({
    ...parseSeconds(value, { daysPerWeek: 7, hoursPerDay: 24 }),
    seconds: value,
  });

/**
 * Takes the raw median value arrays and converts them into a useful object
 * containing the string for display in the path navigation
 * ie. converts [{ id: 'test', value: 172800 }] => { 'test': '2d' }
 *
 * @param {Array} Medians - Array of stage median objects, each contains a `id`, `value` and `error`
 * @returns {Object} Returns key value pair with the stage name and its display median value
 */
export const formatMedianValues = (medians = []) =>
  medians.reduce((acc, { id, value = 0 }) => {
    return {
      ...acc,
      [id]: value ? medianTimeToParsedSeconds(value) : '-',
    };
  }, {});

export const filterStagesByHiddenStatus = (stages = [], isHidden = true) =>
  stages.filter(({ hidden = false }) => hidden === isHidden);
