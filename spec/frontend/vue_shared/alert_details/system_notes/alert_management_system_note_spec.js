import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SystemNote from '~/vue_shared/alert_details/components/system_notes/system_note.vue';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[1];

describe('Alert Details System Note', () => {
  let wrapper;

  function mountComponent({ stubs = {} } = {}) {
    wrapper = shallowMount(SystemNote, {
      propsData: {
        note: { ...mockAlert.notes.nodes[0] },
      },
      stubs,
    });
  }

  describe('System notes', () => {
    beforeEach(() => {
      mountComponent({});
    });

    it('renders the correct system note', () => {
      const noteId = wrapper.find('.note-wrapper').attributes('id');
      const iconName = wrapper.findComponent(GlIcon).attributes('name');

      expect(noteId).toBe('note_1628');
      expect(iconName).toBe(mockAlert.notes.nodes[0].systemNoteIconName);
    });
  });
});
