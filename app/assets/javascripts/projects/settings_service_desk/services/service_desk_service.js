import axios from '~/lib/utils/axios_utils';

class ServiceDeskService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  toggleServiceDesk(enable) {
    return axios.put(this.endpoint, { service_desk_enabled: enable });
  }

  updateTemplate({ selectedTemplate, outgoingName, projectKey = '' }, isEnabled) {
    const body = {
      issue_template_key: selectedTemplate,
      outgoing_name: outgoingName,
      project_key: projectKey,
      service_desk_enabled: isEnabled,
    };
    return axios.put(this.endpoint, body);
  }
}

export default ServiceDeskService;
