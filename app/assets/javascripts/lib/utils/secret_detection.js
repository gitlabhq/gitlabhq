import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { s__, __ } from '~/locale';

export const i18n = {
  defaultPrompt: s__(
    'SecretDetection|This comment appears to have a token in it. Are you sure you want to add it?',
  ),
  descriptionPrompt: s__(
    'SecretDetection|This description appears to have a token in it. Are you sure you want to add it?',
  ),
  primaryBtnText: __('Proceed'),
};

export const containsSensitiveToken = (message) => {
  const patPrefix = window.gon?.pat_prefix || 'glpat-';

  const sensitiveDataPatterns = [
    {
      name: 'GitLab Personal Access Token',
      regex: `${patPrefix}[0-9a-zA-Z_-]{20}`,
    },
    {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      name: 'Feed Token',
      regex: 'feed_token=((glft-)?[0-9a-zA-Z_-]{20}|glft-[a-h0-9]+-[0-9]+_)',
    },
    {
      name: 'GitLab OAuth Application Secret',
      regex: `gloas-[0-9a-zA-Z_-]{64}`,
    },
    {
      name: 'GitLab Deploy Token',
      regex: `gldt-[0-9a-zA-Z_-]{20}`,
    },
  ];

  for (const rule of sensitiveDataPatterns) {
    const regex = new RegExp(rule.regex, 'gi');
    if (regex.test(message)) {
      return true;
    }
  }
  return false;
};

export async function confirmSensitiveAction(prompt = i18n.defaultPrompt) {
  const confirmed = await confirmAction(prompt, {
    primaryBtnVariant: 'danger',
    primaryBtnText: i18n.primaryBtnText,
  });
  if (!confirmed) {
    return false;
  }
  return true;
}
