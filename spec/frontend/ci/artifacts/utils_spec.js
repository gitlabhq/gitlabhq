import getJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { totalArtifactsSizeForJob } from '~/ci/artifacts/utils';

const job = getJobArtifactsResponse.data.project.jobs.nodes[0];
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
