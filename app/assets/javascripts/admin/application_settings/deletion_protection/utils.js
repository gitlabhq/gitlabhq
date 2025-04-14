import { parseBoolean } from '~/lib/utils/common_utils';

export const parseFormProps = ({
  deletionAdjournedPeriod,
  delayedGroupDeletion,
  delayedProjectDeletion,
}) => ({
  deletionAdjournedPeriod:
    deletionAdjournedPeriod !== undefined ? parseInt(deletionAdjournedPeriod, 10) : undefined,
  delayedGroupDeletion: parseBoolean(delayedGroupDeletion),
  delayedProjectDeletion: parseBoolean(delayedProjectDeletion),
});
