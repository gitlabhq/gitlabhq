import { numberToHumanSize } from '~/lib/utils/number_utils';
import { ARCHIVE_FILE_TYPE, METADATA_FILE_TYPE } from './constants';

export const totalArtifactsSizeForJob = (job) =>
  numberToHumanSize(
    job.artifacts.nodes
      .map((artifact) => Number(artifact.size))
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
    hasArtifacts: jobNode.artifacts.nodes.length > 0,
    hasMetadata: jobNode.artifacts.nodes.some(
      (artifact) => artifact.fileType === METADATA_FILE_TYPE,
    ),
    ...jobNode,
  };
};
