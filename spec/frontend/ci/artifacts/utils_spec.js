import getJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import {
  totalArtifactsSizeForJob,
  mapArchivesToJobNodes,
  mapBooleansToJobNodes,
} from '~/ci/artifacts/utils';

const job = getJobArtifactsResponse.data.project.jobs.nodes[0];
const emptyJob = {
  ...job,
  artifacts: { nodes: [] },
};
const artifacts = job.artifacts.nodes;

describe('totalArtifactsSizeForJob', () => {
  it('adds artifact sizes together', () => {
    expect(totalArtifactsSizeForJob(job)).toBe(
      numberToHumanSize(
        Number(artifacts[0].size) + Number(artifacts[1].size) + Number(artifacts[2].size),
      ),
    );
  });
});

describe('mapArchivesToJobNodes', () => {
  it('sets archive to the archive artifact for each job node', () => {
    expect([job, emptyJob].map(mapArchivesToJobNodes)).toMatchObject([
      { archive: { name: 'ci_build_artifacts.zip' } },
      { archive: {} },
    ]);
  });
});

describe('mapBooleansToJobNodes', () => {
  it('sets hasArtifacts and hasMetadata for each job node', () => {
    expect([job, emptyJob].map(mapBooleansToJobNodes)).toMatchObject([
      { hasArtifacts: true, hasMetadata: true },
      { hasArtifacts: false, hasMetadata: false },
    ]);
  });
});
