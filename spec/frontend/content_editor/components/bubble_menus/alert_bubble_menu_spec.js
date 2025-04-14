import { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import AlertBubbleMenu from '~/content_editor/components/bubble_menus/alert_bubble_menu.vue';
import { stubComponent } from 'helpers/stub_component';
import eventHubFactory from '~/helpers/event_hub_factory';
import Alert from '~/content_editor/extensions/alert';
import AlertTitle from '~/content_editor/extensions/alert_title';
import { ALERT_TYPES, DEFAULT_ALERT_TITLES } from '~/content_editor/constants/alert_types';
import {
  createTestEditor,
  emitEditorEvent,
  createTransactionWithMeta,
  mockChainedCommands,
} from '../../test_utils';

describe('content_editor/components/bubble_menus/alert_bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;
  let commands;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [Alert, AlertTitle] });
    contentEditor = {};
    eventHub = eventHubFactory();
  };

  const buildWrapper = () => {
    wrapper = mountExtended(AlertBubbleMenu, {
      provide: {
        tiptapEditor,
        contentEditor,
        eventHub,
      },
      stubs: {
        BubbleMenu: stubComponent(BubbleMenu),
      },
    });
  };

  const findBubbleMenu = () => wrapper.findComponent(BubbleMenu);
  const findAlertTypeListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findRemoveButton = () => wrapper.findByTestId('remove-alert');

  const showBubbleMenu = async () => {
    findBubbleMenu().vm.$emit('show');
    await emitEditorEvent({
      event: 'transaction',
      tiptapEditor,
      params: { transaction: createTransactionWithMeta() },
    });
    await nextTick();
  };

  beforeEach(() => {
    buildEditor();
    buildWrapper();
  });

  it('renders bubble menu component', async () => {
    await showBubbleMenu();
    expect(findBubbleMenu().classes()).toEqual(['gl-rounded-base', 'gl-bg-overlap', 'gl-shadow']);
  });

  it('shows alert type listbox', async () => {
    await showBubbleMenu();
    expect(findAlertTypeListbox().exists()).toBe(true);
  });

  it('shows remove alert button', async () => {
    await showBubbleMenu();
    expect(findRemoveButton().exists()).toBe(true);
  });

  describe('alert type selection', () => {
    it('updates alert type when selected from listbox', async () => {
      commands = mockChainedCommands(tiptapEditor, ['focus', 'updateAttributes', 'run']);

      await showBubbleMenu();
      const newAlertType = ALERT_TYPES.WARNING;
      findAlertTypeListbox().vm.$emit('select', newAlertType);
      expect(commands.updateAttributes).toHaveBeenCalledWith(Alert.name, {
        type: newAlertType,
      });
    });
  });

  describe('remove alert', () => {
    it('removes alert when remove button is clicked', async () => {
      commands = mockChainedCommands(tiptapEditor, ['focus', 'deleteNode', 'run']);

      await showBubbleMenu();
      findRemoveButton().vm.$emit('click');
      expect(commands.deleteNode).toHaveBeenCalledWith(Alert.name);
    });
  });

  describe('bubble menu visibility', () => {
    it('is visible when Alert is active', () => {
      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(true);

      expect(wrapper.vm.shouldShow({ editor: tiptapEditor })).toBe(true);
    });

    it('is not visible when Alert is not active', () => {
      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(false);

      expect(wrapper.vm.shouldShow({ editor: tiptapEditor })).toBe(false);
    });
  });

  describe('updateAlertTypeToState method', () => {
    it('updates alertType and selectedAlertType when called', async () => {
      const mockAlertType = ALERT_TYPES.NOTE;
      jest.spyOn(tiptapEditor, 'getAttributes').mockReturnValue({ type: mockAlertType });

      await wrapper.vm.updateAlertTypeToState();
      expect(wrapper.vm.alertType).toBe(mockAlertType);
      expect(wrapper.vm.selectedAlertType).toEqual({
        text: DEFAULT_ALERT_TITLES[mockAlertType],
        value: mockAlertType,
      });
    });
  });
});
