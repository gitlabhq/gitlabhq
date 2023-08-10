import { GlTable, GlBadge } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import TriggersList from '~/ci_settings_pipeline_triggers/components/triggers_list.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { triggers } from '../mock_data';

describe('TriggersList', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(TriggersList, {
      propsData: { triggers, ...props },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaderAt = (i) => wrapper.findAll('thead th').at(i);
  const findRows = () => wrapper.findAll('tbody tr');
  const findRowAt = (i) => findRows().at(i);
  const findCell = (i, col) => findRowAt(i).findAll('td').at(col);
  const findClipboardBtn = (i) => findCell(i, 0).findComponent(ClipboardButton);
  const findInvalidBadge = (i) => findCell(i, 0).findComponent(GlBadge);
  const findEditBtn = (i) => findRowAt(i).find('[data-testid="edit-btn"]');
  const findRevokeBtn = (i) => findRowAt(i).find('[data-testid="trigger_revoke_button"]');
  const findRevealHideButton = () =>
    document.querySelector('[data-testid="reveal-hide-values-button"]');

  describe('With triggers set', () => {
    beforeEach(async () => {
      setHTMLFixture(`
        <button data-testid="reveal-hide-values-button">Reveal values</button>
      `);

      createComponent();

      await nextTick();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('displays a table with expected headers', () => {
      const headers = ['Token', 'Description', 'Owner', 'Last Used', 'Actions'];
      headers.forEach((header, i) => {
        expect(findHeaderAt(i).text()).toBe(header);
      });
    });

    it('displays a "Reveal/Hide values" button', async () => {
      const revealHideButton = findRevealHideButton();

      expect(Boolean(revealHideButton)).toBe(true);
      expect(revealHideButton.innerText).toBe('Reveal values');

      await revealHideButton.click();

      expect(revealHideButton.innerText).toBe('Hide values');
    });

    it('displays a table with rows', async () => {
      await findRevealHideButton().click();

      expect(findRows()).toHaveLength(triggers.length);

      const [trigger] = triggers;

      expect(findCell(0, 0).text()).toBe(trigger.token);
      expect(findCell(0, 1).text()).toBe(trigger.description);
      expect(findCell(0, 2).text()).toContain(trigger.owner.name);
    });

    it('displays a "copy to cliboard" button for exposed tokens', () => {
      expect(findClipboardBtn(0).exists()).toBe(true);
      expect(findClipboardBtn(0).props('text')).toBe(triggers[0].token);

      expect(findClipboardBtn(1).exists()).toBe(false);
    });

    it('displays an "invalid" label for tokens without access', () => {
      expect(findInvalidBadge(0).exists()).toBe(false);

      expect(findInvalidBadge(1).exists()).toBe(true);
    });

    it('displays a time ago label when last used', () => {
      expect(findCell(0, 3).text()).toBe('Never');

      expect(findCell(1, 3).findComponent(TimeAgoTooltip).props('time')).toBe(triggers[1].lastUsed);
    });

    it('displays actions in a rows', () => {
      const [data] = triggers;
      const confirmWarning =
        'By revoking a trigger you will break any processes making use of it. Are you sure?';

      expect(findEditBtn(0).attributes('href')).toBe(data.editProjectTriggerPath);

      expect(findRevokeBtn(0).attributes('href')).toBe(data.projectTriggerPath);
      expect(findRevokeBtn(0).attributes('data-method')).toBe('delete');
      expect(findRevokeBtn(0).attributes('data-confirm')).toBe(confirmWarning);
    });
  });

  describe('when there are no triggers set', () => {
    beforeEach(() => {
      createComponent({ triggers: [] });
    });

    it('does not display a table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('displays a message', () => {
      expect(wrapper.text()).toBe(
        'No triggers have been created yet. Add one using the form above.',
      );
    });
  });
});
