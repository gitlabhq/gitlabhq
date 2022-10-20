import { numberToHumanSize } from '~/lib/utils/number_utils';
import { ARCHIVE_FILE_TYPE, JOB_STATUS_GROUP_SUCCESS } from './constants';

export const totalArtifactsSizeForJob = (job) =>
  numberToHumanSize(
    job.artifacts.nodes
      .map((artifact) => artifact.size)
      .reduce((total, artifact) => total + artifact, 0),
  );

export const mapArchivesToJobNodes = (jobNode) => {
  return {
    archive: {
      ...jobNode.artifacts.nodes.find((artifact) => artifact.fileType === ARCHIVE_FILE_TYPE),
    },
    ...jobNode,
  };
};

export const mapBooleansToJobNodes = (jobNode) => {
  return {
    succeeded: jobNode.detailedStatus.group === JOB_STATUS_GROUP_SUCCESS,
    hasArtifacts: jobNode.artifacts.nodes.length > 0,
    ...jobNode,
  };
};
