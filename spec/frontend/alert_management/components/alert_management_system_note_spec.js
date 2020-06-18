import { shallowMount } from '@vue/test-utils';
import SystemNote from '~/alert_management/components/system_notes/system_note.vue';
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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('System notes', () => {
    beforeEach(() => {
      mountComponent({});
    });

    it('renders the correct system note', () => {
      expect(wrapper.find('.note-wrapper').attributes('id')).toBe('note_1628');
    });
  });
});
