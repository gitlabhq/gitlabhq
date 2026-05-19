import { slugify } from '~/lib/utils/text_utility';
import InternalEvents from '~/tracking/internal_events';

const PLACEHOLDER_GROUP = 'my-group';
const PLACEHOLDER_PROJECT = 'my-project';

const el = (id) => document.getElementById(id);

export function initOnboardingUrlPreview() {
  const groupInput = el('js-onboarding-group-name');
  const projectInput = el('js-onboarding-project-name');
  const groupHidden = el('js-onboarding-group-path');
  const projectHidden = el('js-onboarding-project-path');
  const rootUrlContainer = document.querySelector('[data-onboarding-root-url]');
  const rootUrlSpan = document.querySelector('.js-onboarding-root-url');
  const groupPathSpan = document.querySelector('[data-testid="url-group-path"]');
  const projectPathSpan = document.querySelector('[data-testid="url-project-path"]');

  if (!groupInput || !projectInput || !rootUrlContainer) return;

  const rootUrl = rootUrlContainer.dataset.onboardingRootUrl;

  function update() {
    const groupSlug = slugify(groupInput.value) || PLACEHOLDER_GROUP;
    const projectSlug = slugify(projectInput.value) || PLACEHOLDER_PROJECT;

    if (rootUrlSpan) rootUrlSpan.textContent = rootUrl;
    if (groupPathSpan) groupPathSpan.textContent = groupSlug;
    if (projectPathSpan) projectPathSpan.textContent = projectSlug;

    if (groupHidden) groupHidden.value = groupInput.value.trim() ? groupSlug : '';
    if (projectHidden) projectHidden.value = projectInput.value.trim() ? projectSlug : '';
  }

  const templateSelect = el('project_project_template_name');
  if (templateSelect) {
    templateSelect.addEventListener('change', () => {
      if (templateSelect.value) {
        InternalEvents.trackEvent('select_project_template', { label: templateSelect.value });
      }
    });
  }

  groupInput.addEventListener('input', update);
  projectInput.addEventListener('input', update);
  update();
}
