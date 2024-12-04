/* eslint-disable @gitlab/require-i18n-strings */
const sensitiveDataPatterns = () => {
  const patPrefix = window.gon?.pat_prefix || 'glpat-';

  return [
    {
      name: 'GitLab personal access token',
      regex: `${patPrefix}[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab personal access token (routable)',
      regex: `${patPrefix}(?<base64_payload>[0-9a-zA-Z_-]{27,300})\\.(?<base64_payload_length>[0-9a-z]{2})(?<crc32>[0-9a-z]{7})`,
    },
    {
      name: 'Feed Token',
      regex: 'feed_token=[0-9a-zA-Z_-]{20}|glft-[0-9a-zA-Z_-]{20}|glft-[a-h0-9]+-[0-9]+_',
    },
    {
      name: 'GitLab OAuth Application Secret',
      regex: `gloas-[0-9a-zA-Z_-]{64}`,
    },
    {
      name: 'GitLab Deploy Token',
      regex: `gldt-[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab SCIM OAuth Access Token',
      regex: `glsoat-[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab CI Build (Job) Token',
      regex: `glcbt-[0-9a-zA-Z]{1,5}_[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab Feature Flags Client Token',
      regex: `glffct-[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab Runner Token',
      regex: 'glrt-[0-9a-zA-Z_-]{20}',
    },
    {
      name: 'GitLab Incoming Mail Token',
      regex: 'glimt-[0-9a-zA-Z_-]{25}',
    },
    {
      name: 'GitLab Agent for Kubernetes Token',
      regex: 'glagent-[0-9a-zA-Z_-]{50}',
    },
    {
      name: 'GitLab Pipeline Trigger Token',
      regex: 'glptt-[0-9a-zA-Z_-]{40}',
    },
    {
      name: 'Anthropic key',
      regex: 'sk-ant-[a-z]{3}\\d{2}-[A-Za-z0-9-_]{86}-[A-Za-z0-9-_]{8}',
    },
  ];
};

export default sensitiveDataPatterns;
