export const extraContext = {
  schema: 'iglu:com.gitlab/design_management_context/jsonschema/1-0-0',
  data: {
    'design-version-number': '1.0.0',
    'design-is-current-version': '1.0.0',
    'internal-object-referrer': 'https://gitlab.com',
    'design-collection-owner': 'GitLab',
  },
};

export const servicePingContext = {
  schema: 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-1',
  data: {
    event_name: 'track_incident_event',
    data_source: 'redis_hll',
  },
};
