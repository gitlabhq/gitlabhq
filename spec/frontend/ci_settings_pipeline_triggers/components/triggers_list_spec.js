import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlTable, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { TYPENAME_CI_TRIGGER } from '~/graphql_shared/constants';
import TriggersList from '~/ci_settings_pipeline_triggers/components/triggers_list.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import EditTriggerModal from '~/ci_settings_pipeline_triggers/components/edit_trigger_modal.vue';
import updatePipelineTriggerMutation from '~/ci_settings_pipeline_triggers/graphql/update_pipeline_trigger.mutation.graphql';
import { triggers, mockPipelineTriggerMutationResponse } from '../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('TriggersList', () => {
  let wrapper;
  let mockApollo;
  let mockUpdatePipelineTriggerMutation;

  const createComponent = (props = {}, apolloProvider = undefined) => {
    wrapper = mountExtended(TriggersList, {
      apolloProvider,
      propsData: { initTriggers: triggers, ...props },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
    });
  };

  const createComponentWithApollo = (props = {}) => {
    const handlers = [[updatePipelineTriggerMutation, mockUpdatePipelineTriggerMutation]];

    mockApollo = createMockApollo(handlers);
    createComponent(props, mockApollo);
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findHeaderAt = (i) => wrapper.findAll('thead th').at(i);
  const findRows = () => wrapper.findAll('tbody tr');
  const findRowAt = (i) => findRows().at(i);
  const findCell = (i, col) => findRowAt(i).findAll('td').at(col);
  const findClipboardBtn = (i) => findCell(i, 0).findComponent(ClipboardButton);
  const findInvalidBadge = (i) => findCell(i, 0).findComponent(GlBadge);
  const findEditBtn = (i) => findRowAt(i).find('[data-testid="edit-btn"]');
  const findModal = () => wrapper.findComponent(EditTriggerModal);
  const findRevokeBtn = (i) => findRowAt(i).find('[data-testid="trigger_revoke_button"]');
  const findRevealHideButton = () =>
    document.querySelector('[data-testid="reveal-hide-values-button"]');

  beforeEach(() => {
    mockUpdatePipelineTriggerMutation = jest.fn();
  });

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
      const headers = ['Token', 'Description', 'Owner', 'Last Used', 'Expires', 'Actions'];
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

    it('displays a time ago label when expiration set', () => {
      expect(findCell(0, 4).text()).toBe('Never');

      expect(findCell(1, 4).findComponent(TimeAgoTooltip).props('time')).toBe(
        triggers[1].expiresAt,
      );
    });

    it('displays actions in a rows', () => {
      const [data] = triggers;
      const confirmWarning =
        'By revoking a trigger token you will break any processes making use of it. Are you sure?';

      expect(findRevokeBtn(0).attributes('href')).toBe(data.projectTriggerPath);
      expect(findRevokeBtn(0).attributes('data-method')).toBe('delete');
      expect(findRevokeBtn(0).attributes('data-confirm')).toBe(confirmWarning);
    });

    it('does not display edit modal yet', () => {
      expect(findModal().exists()).toBe(false);
    });

    describe('when edit button is clicked', () => {
      beforeEach(async () => {
        const editBtn = findEditBtn(0);
        await editBtn.trigger('click');
      });

      it('has modal binding set', () => {
        const { value } = getBinding(findEditBtn(0).element, 'gl-modal');

        expect(value).toBe('edit-trigger-modal');
      });

      it('displays modal', () => {
        expect(findModal().exists()).toBe(true);
        expect(findModal().props()).toEqual({
          modalId: 'edit-trigger-modal',
          trigger: triggers[0],
        });
      });
    });
  });

  describe('when there are no triggers set', () => {
    beforeEach(() => {
      createComponent({ initTriggers: [] });
    });

    it('does not display a table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('displays a message', () => {
      expect(wrapper.text()).toBe(
        'No trigger tokens have been created yet. Add one using the form above.',
      );
    });
  });

  describe('when editing a trigger token', () => {
    const [trigger] = triggers;
    const triggerIndex = 0;
    const updatedDescription = 'This is an updated description.';

    beforeEach(() => {
      createComponentWithApollo();
    });

    const updateTriggerToken = async () => {
      const editBtn = findEditBtn(triggerIndex);
      await editBtn.trigger('click');

      await findModal().vm.$emit('submit', { ...trigger, description: updatedDescription });
      await waitForPromises();
    };

    describe('when mutation is successful', () => {
      beforeEach(() => {
        mockUpdatePipelineTriggerMutation.mockResolvedValue(
          mockPipelineTriggerMutationResponse({ description: updatedDescription }),
        );
      });

      it('calls the mutation with the correct variables', async () => {
        await updateTriggerToken();

        expect(mockUpdatePipelineTriggerMutation).toHaveBeenCalledWith({
          id: convertToGraphQLId(TYPENAME_CI_TRIGGER, trigger.id),
          description: updatedDescription,
        });
      });

      it('updates the description in the table and does not render an alert message', async () => {
        expect(findCell(triggerIndex, 1).text()).toBe(trigger.description);

        await updateTriggerToken();

        expect(findCell(triggerIndex, 1).text()).toBe(updatedDescription);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when mutation returns an error', () => {
      beforeEach(() => {
        mockUpdatePipelineTriggerMutation.mockResolvedValue(
          mockPipelineTriggerMutationResponse({ errors: ['Something went wrong.'] }),
        );
      });

      it('renders an alert message and does not update the table', async () => {
        expect(findCell(triggerIndex, 1).text()).toBe(trigger.description);

        await updateTriggerToken();

        expect(createAlert).toHaveBeenCalledWith({ message: 'Something went wrong.' });
        expect(findCell(triggerIndex, 1).text()).toBe(trigger.description);
      });
    });

    describe('when mutation fails', () => {
      beforeEach(() => {
        mockUpdatePipelineTriggerMutation.mockRejectedValue(new Error());
      });

      it('renders an alert message and does not update the table', async () => {
        expect(findCell(triggerIndex, 1).text()).toBe(trigger.description);

        await updateTriggerToken();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while updating the trigger token. Please try again.',
        });
        expect(findCell(triggerIndex, 1).text()).toBe(trigger.description);
      });
    });
  });
});
