import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ServiceDeskRoot from './components/service_desk_root.vue';

Vue.use(GlToast);

export default () => {
  const el = document.querySelector('.js-service-desk-setting-root');

  if (!el) {
    return false;
  }

  const {
    serviceDeskEmail,
    serviceDeskEmailEnabled,
    enabled,
    issueTrackerEnabled,
    endpoint,
    incomingEmail,
    outgoingName,
    projectKey,
    ticketsConfidentialByDefault,
    reopenIssueOnExternalParticipantNote,
    addExternalParticipantsFromCc,
    selectedTemplate,
    selectedFileTemplateProjectId,
    templates,
    publicProject,
    customEmailEndpoint,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      serviceDeskEmail,
      serviceDeskEmailEnabled: parseBoolean(serviceDeskEmailEnabled),
      endpoint,
      initialIncomingEmail: incomingEmail,
      initialIsEnabled: parseBoolean(enabled),
      isIssueTrackerEnabled: parseBoolean(issueTrackerEnabled),
      outgoingName,
      projectKey,
      areTicketsConfidentialByDefault: parseBoolean(ticketsConfidentialByDefault),
      reopenIssueOnExternalParticipantNote: parseBoolean(reopenIssueOnExternalParticipantNote),
      addExternalParticipantsFromCc: parseBoolean(addExternalParticipantsFromCc),
      selectedTemplate,
      selectedFileTemplateProjectId: parseInt(selectedFileTemplateProjectId, 10) || null,
      templates: JSON.parse(templates),
      publicProject: parseBoolean(publicProject),
      customEmailEndpoint,
    },
    render: (createElement) => createElement(ServiceDeskRoot),
  });
};
