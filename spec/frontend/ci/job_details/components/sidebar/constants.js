import { getTimeago } from '~/lib/utils/datetime_utility';

const expireAt = '2018-08-14T09:38:49.157Z';

export const lockedText =
  'These artifacts are the latest. They will not be deleted (even if expired) until newer artifacts are available.';

export const formattedDate = getTimeago().format(expireAt);

export const expiredArtifact = {
  expireAt,
  expired: true,
  locked: false,
};

export const nonExpiredArtifact = {
  downloadPath: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/download',
  browsePath: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/browse',
  keepPath: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/keep',
  expireAt,
  expired: false,
  locked: false,
};

export const lockedExpiredArtifact = {
  ...expiredArtifact,
  downloadPath: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/download',
  browsePath: '/gitlab-org/gitlab-foss/-/jobs/98314558/artifacts/browse',
  expired: true,
  locked: true,
};

export const lockedNonExpiredArtifact = {
  ...nonExpiredArtifact,
  keepPath: undefined,
  locked: true,
};

export const sastReport = [
  {
    file_type: 'sast',
    file_format: 'raw',
    size: 2036,
    download_path: '/root/security-reports/-/jobs/12281/artifacts/download?file_type=sast',
  },
];

export const dastReport = [
  {
    file_type: 'dast',
    file_format: 'raw',
    size: 10830,
    download_path: '/root/security-reports/-/jobs/12273/artifacts/download?file_type=dast',
  },
];
