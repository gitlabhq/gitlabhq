import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { dasherize } from '~/lib/utils/text_utility';
import { __ } from '../locale';
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

const mapToStage = (permissions, item) => {
  const slug = dasherize(item.name.toLowerCase());
  return {
    ...item,
    slug,
    active: false,
    isUserAllowed: permissions[slug],
    emptyStageText: EMPTY_STAGE_TEXTS[slug],
    component: `stage-${slug}-component`,
  };
};

const mapToSummary = ({ value, ...rest }) => ({ ...rest, value: value || '-' });

export const decorateData = (data = {}) => {
  const { permissions, stats, summary } = data;
  return {
    stages: stats?.map((item) => mapToStage(permissions, item)) || [],
    summary: summary?.map((item) => mapToSummary(item)) || [],
  };
};
