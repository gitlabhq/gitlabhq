import { escapeRegExp } from 'lodash-es';

/* eslint-disable @gitlab/require-i18n-strings */
const sensitiveDataPatterns = () => {
  const patPrefix = escapeRegExp(window.gon?.pat_prefix) || 'glpat-';
  const instanceTokenPrefix = escapeRegExp(window.gon?.instance_token_prefix);

  // Create optional instance prefix pattern
  const instancePrefixPattern = instanceTokenPrefix ? `(${instanceTokenPrefix}-)?` : '';

  // For PATS, we need to make sure that we still support existing custom pat prefixes, as well as instance-glpat- and glpat-
  const patPrefixPattern = instanceTokenPrefix
    ? `(${instanceTokenPrefix}-glpat-|${patPrefix}|glpat-)`
    : `(${patPrefix}|glpat-)`;

  return [
    {
      name: 'GitLab personal access token',
      regex: `${patPrefixPattern}[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab personal access token (routable)',
      regex: `${patPrefixPattern}(?<base64_payload>[0-9a-zA-Z_-]{27,300})\\.[0-9a-z]{2}\\.(?<base64_payload_length>[0-9a-z]{2})(?<crc32>[0-9a-z]{7})`,
    },
    {
      name: 'Feed Token',
      regex: `feed_token=${instancePrefixPattern}[0-9a-zA-Z_-]{20}|${instancePrefixPattern}glft-[0-9a-zA-Z_-]{20}|${instancePrefixPattern}glft-[a-h0-9]+-[0-9]+_`,
    },
    {
      name: 'GitLab OAuth Application Secret',
      regex: `${instancePrefixPattern}gloas-[0-9a-zA-Z_-]{64}`,
    },
    {
      name: 'GitLab Deploy Token',
      regex: `${instancePrefixPattern}gldt-[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab SCIM OAuth Access Token',
      regex: `${instancePrefixPattern}glsoat-[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab CI Build (Job) Token',
      regex: `${instancePrefixPattern}glcbt-[0-9a-zA-Z]{1,5}_[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab Feature Flags Client Token',
      regex: `${instancePrefixPattern}glffct-[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab Runner Token',
      regex: `${instancePrefixPattern}(?<registration_type>glrt-)?(?<runner_type>t\\d_)[0-9a-zA-Z_-]{20}`,
    },
    {
      name: 'GitLab Runner Token (routable)',
      regex: `${instancePrefixPattern}(?<registration_type>glrtr?-)?(?<base64_payload>[0-9a-zA-Z_-]{27,300})\\.[0-9a-z]{2}\\.(?<base64_payload_length>[0-9a-z]{2})(?<crc32>[0-9a-z]{7})`,
    },
    {
      name: 'GitLab Incoming Mail Token',
      regex: `${instancePrefixPattern}glimt-[0-9a-zA-Z_-]{25}`,
    },
    {
      name: 'GitLab Agent for Kubernetes Token',
      regex: `${instancePrefixPattern}glagent-[0-9a-zA-Z_-]{50}`,
    },
    {
      name: 'GitLab Pipeline Trigger Token',
      regex: `${instancePrefixPattern}glptt-[0-9a-zA-Z_-]{40}`,
    },
    {
      name: 'Anthropic key',
      regex: 'sk-ant-[a-z]{3}\\d{2}-[A-Za-z0-9-_]{86}-[A-Za-z0-9-_]{8}',
    },
  ];
};

export default sensitiveDataPatterns;
