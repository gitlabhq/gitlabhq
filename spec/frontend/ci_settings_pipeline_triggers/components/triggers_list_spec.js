import { GlTable, GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import TriggersList from '~/ci_settings_pipeline_triggers/components/triggers_list.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { triggers } from '../mock_data';

describe('TriggersList', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(TriggersList, {
      propsData: { triggers, ...props },
    });
  };

  const findTable = () => wrapper.find(GlTable);
  const findHeaderAt = (i) => wrapper.findAll('thead th').at(i);
  const findRows = () => wrapper.findAll('tbody tr');
  const findRowAt = (i) => findRows().at(i);
  const findCell = (i, col) => findRowAt(i).findAll('td').at(col);
  const findClipboardBtn = (i) => findCell(i, 0).find(ClipboardButton);
  const findInvalidBadge = (i) => findCell(i, 0).find(GlBadge);
  const findEditBtn = (i) => findRowAt(i).find('[data-testid="edit-btn"]');
  const findRevokeBtn = (i) => findRowAt(i).find('[data-testid="trigger_revoke_button"]');

  beforeEach(() => {
    createComponent();

    return wrapper.vm.$nextTick();
  });

  it('displays a table with expected headers', () => {
    const headers = ['Token', 'Description', 'Owner', 'Last Used', ''];
    headers.forEach((header, i) => {
      expect(findHeaderAt(i).text()).toBe(header);
    });
  });

  it('displays a table with rows', () => {
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

    expect(findCell(1, 3).find(TimeAgoTooltip).props('time')).toBe(triggers[1].lastUsed);
  });

  it('displays actions in a rows', () => {
    const [data] = triggers;

    expect(findEditBtn(0).attributes('href')).toBe(data.editProjectTriggerPath);

    expect(findRevokeBtn(0).attributes('href')).toBe(data.projectTriggerPath);
    expect(findRevokeBtn(0).attributes('data-method')).toBe('delete');
    expect(findRevokeBtn(0).attributes('data-confirm')).toBeTruthy();
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
