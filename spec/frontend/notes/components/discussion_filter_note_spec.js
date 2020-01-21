import Vue from 'vue';
import DiscussionFilterNote from '~/notes/components/discussion_filter_note.vue';
import eventHub from '~/notes/event_hub';

import mountComponent from '../../helpers/vue_mount_component_helper';

describe('DiscussionFilterNote component', () => {
  let vm;

  const createComponent = () => {
    const Component = Vue.extend(DiscussionFilterNote);

    return mountComponent(Component);
  };

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('timelineContent', () => {
      it('returns string containing instruction for switching feed type', () => {
        expect(vm.timelineContent).toBe(
          "You're only seeing <b>other activity</b> in the feed. To add a comment, switch to one of the following options.",
        );
      });
    });
  });

  describe('methods', () => {
    describe('selectFilter', () => {
      it('emits `dropdownSelect` event on `eventHub` with provided param', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        vm.selectFilter(1);

        expect(eventHub.$emit).toHaveBeenCalledWith('dropdownSelect', 1);
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(vm.$el.classList.contains('discussion-filter-note')).toBe(true);
    });

    it('renders comment icon element', () => {
      expect(vm.$el.querySelector('.timeline-icon svg use').getAttribute('xlink:href')).toContain(
        'comment',
      );
    });

    it('renders filter information note', () => {
      expect(vm.$el.querySelector('.timeline-content').innerText.trim()).toContain(
        "You're only seeing other activity in the feed. To add a comment, switch to one of the following options.",
      );
    });

    it('renders filter buttons', () => {
      const buttonsContainerEl = vm.$el.querySelector('.discussion-filter-actions');

      expect(buttonsContainerEl.querySelector('button:first-child').innerText.trim()).toContain(
        'Show all activity',
      );

      expect(buttonsContainerEl.querySelector('button:last-child').innerText.trim()).toContain(
        'Show comments only',
      );
    });

    it('clicking `Show all activity` button calls `selectFilter("all")` method', () => {
      const showAllBtn = vm.$el.querySelector('.discussion-filter-actions button:first-child');
      jest.spyOn(vm, 'selectFilter').mockImplementation(() => {});

      showAllBtn.dispatchEvent(new Event('click'));

      expect(vm.selectFilter).toHaveBeenCalledWith(0);
    });

    it('clicking `Show comments only` button calls `selectFilter("comments")` method', () => {
      const showAllBtn = vm.$el.querySelector('.discussion-filter-actions button:last-child');
      jest.spyOn(vm, 'selectFilter').mockImplementation(() => {});

      showAllBtn.dispatchEvent(new Event('click'));

      expect(vm.selectFilter).toHaveBeenCalledWith(1);
    });
  });
});
