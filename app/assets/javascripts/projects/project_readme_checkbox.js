import { s__ } from '~/locale';
import eventHub from '~/projects/new/event_hub';

export const DISABLED_MESSAGE = s__(
  'ProjectsNew|You cannot push the initial commit because the default branch is protected. Contact an Owner or administrator for help.',
);
export const DEFAULT_HELP_TEXT = s__(
  'ProjectsNew|Allows you to immediately clone this project’s repository. Skip this if you plan to push up an existing repository.',
);

function updateReadmeCheckbox({ canPushInitialCommit }) {
  const checkbox = document.querySelector('[data-testid="initialize-with-readme-checkbox"]');
  if (!checkbox) return;

  const isDisabled = canPushInitialCommit === false;

  checkbox.disabled = isDisabled;
  checkbox.checked = !isDisabled;

  const helpText = checkbox.parentElement?.querySelector(
    '[data-testid="pajamas-component-help-text"]',
  );
  if (helpText) {
    helpText.textContent = isDisabled ? DISABLED_MESSAGE : DEFAULT_HELP_TEXT;
  }
}

export default function initReadmeCheckboxToggle() {
  eventHub.$on('update-readme-checkbox', updateReadmeCheckbox);
}
