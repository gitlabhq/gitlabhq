import Vue from 'vue';

import SidebarDatepicker from 'ee/epics/sidebar/components/sidebar_date_picker.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockDatePickerProps } from 'ee_spec/epics/epic_show/mock_data';

const createComponent = (datePickerProps = mockDatePickerProps) => {
  const Component = Vue.extend(SidebarDatepicker);

  return mountComponent(Component, datePickerProps);
};

describe('SidebarParticipants', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('return data props with uniqueId for `fieldName`', () => {
      expect(vm.fieldName).toContain('dateType_');
    });
  });

  describe('computed', () => {
    describe('selectedAndEditable', () => {
      it('returns `true` when both `selectedDate` is defined and `editable` is true', done => {
        vm.selectedDate = new Date();
        Vue.nextTick()
          .then(() => {
            expect(vm.selectedAndEditable).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('selectedDateWords', () => {
      it('returns full date string in words based on `selectedDate` prop value', done => {
        vm.selectedDate = new Date(2018, 0, 1);
        Vue.nextTick()
          .then(() => {
            expect(vm.selectedDateWords).toBe('Jan 1, 2018');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('dateFixedWords', () => {
      it('returns full date string in words based on `dateFixed` prop value', done => {
        vm.dateFixed = new Date(2018, 0, 1);
        Vue.nextTick()
          .then(() => {
            expect(vm.dateFixedWords).toBe('Jan 1, 2018');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('dateFromMilestonesWords', () => {
      it('returns full date string in words when `dateFromMilestones` is defined', done => {
        vm.dateFromMilestones = new Date(2018, 0, 1);
        Vue.nextTick()
          .then(() => {
            expect(vm.dateFromMilestonesWords).toBe('Jan 1, 2018');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns `None` when `dateFromMilestones` is not defined', () => {
        expect(vm.dateFromMilestonesWords).toBe('None');
      });
    });

    describe('collapsedText', () => {
      it('returns value of `selectedDateWords` when it is defined', done => {
        vm.selectedDate = new Date(2018, 0, 1);
        Vue.nextTick()
          .then(() => {
            expect(vm.collapsedText).toBe('Jan 1, 2018');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns `None` when `selectedDateWords` is not defined', () => {
        expect(vm.collapsedText).toBe('None');
      });
    });

    describe('popoverOptions', () => {
      it('returns popover config object containing title with appropriate string', () => {
        expect(vm.popoverOptions.title).toBe('These dates affect how your epics appear in the roadmap. Dates from milestones come from the milestones assigned to issues in the epic. You can also set fixed dates or remove them entirely.');
      });

      it('returns popover config object containing `content` with href pointing to correct documentation', () => {
        expect(vm.popoverOptions.content.trim()).toBe('<a href="https://docs.gitlab.com/ee/user/group/epics/#Dates">More information</a>');
      });
    });

    describe('dateInvalidPopoverOptions', () => {
      it('returns popover config object containing title with appropriate string', () => {
        expect(vm.dateInvalidPopoverOptions.title).toBe('Selected date is invalid');
      });

      it('returns popover config object containing `content` with href pointing to correct documentation', () => {
        expect(vm.dateInvalidPopoverOptions.content.trim()).toBe('<a href="https://docs.gitlab.com/ee/user/group/epics/#Dates">How can I solve this?</a>');
      });
    });
  });

  describe('methods', () => {
    describe('getPopoverConfig', () => {
      it('returns popover config object with provided `title` and `content` values', () => {
        const title = 'Popover title';
        const content = 'This is a popover content';
        const popoverConfig = vm.getPopoverConfig({ title, content });
        const expectedPopoverConfig = {
          html: true,
          trigger: 'focus',
          container: 'body',
          boundary: 'viewport',
          template: '<div class="popover-header"></div>',
          title,
          content,
        };

        Object.keys(popoverConfig).forEach((key) => {
          if (key === 'template') {
            expect(popoverConfig[key]).toContain(expectedPopoverConfig[key]);
          } else {
            expect(popoverConfig[key]).toBe(expectedPopoverConfig[key]);
          }
        });
      });
    });

    describe('stopEditing', () => {
      it('sets `editing` prop to `false` and emits `toggleDateType` event on component', () => {
        spyOn(vm, '$emit');
        vm.stopEditing();
        expect(vm.editing).toBe(false);
        expect(vm.$emit).toHaveBeenCalledWith('toggleDateType', true, true);
      });
    });

    describe('toggleDatePicker', () => {
      it('flips value of `editing` prop from `true` to `false` and vice-versa', () => {
        vm.editing = true;
        vm.toggleDatePicker();
        expect(vm.editing).toBe(false);
      });
    });

    describe('newDateSelected', () => {
      it('sets `editing` prop to `false` and emits `saveDate` event on component', () => {
        spyOn(vm, '$emit');
        const date = new Date();
        vm.newDateSelected(date);
        expect(vm.editing).toBe(false);
        expect(vm.$emit).toHaveBeenCalledWith('saveDate', date);
      });
    });

    describe('toggleDateType', () => {
      it('emits `toggleDateType` event on component', () => {
        spyOn(vm, '$emit');
        vm.toggleDateType(true);
        expect(vm.$emit).toHaveBeenCalledWith('toggleDateType', true);
      });
    });

    describe('toggleSidebar', () => {
      it('emits `toggleCollapse` event on component', () => {
        spyOn(vm, '$emit');
        vm.toggleSidebar();
        expect(vm.$emit).toHaveBeenCalledWith('toggleCollapse');
      });
    });
  });

  describe('template', () => {
    it('renders component container element', () => {
      expect(vm.$el.classList.contains('block', 'date', 'epic-date')).toBe(true);
    });

    it('renders collapsed calendar icon component', () => {
      expect(vm.$el.querySelector('.sidebar-collapsed-icon')).not.toBe(null);
    });

    it('renders collapse button when `showToggleSidebar` prop is `true`', done => {
      vm.showToggleSidebar = true;
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('button.btn-sidebar-action')).not.toBe(null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders title element', () => {
      expect(vm.$el.querySelector('.title')).not.toBe(null);
    });

    it('renders loading icon when `isLoading` prop is true', done => {
      vm.isLoading = true;
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.loading-container')).not.toBe(null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders help icon', () => {
      const helpIconEl = vm.$el.querySelector('.help-icon');
      expect(helpIconEl).not.toBe(null);
      expect(helpIconEl.getAttribute('tabindex')).toBe('0');
      expect(helpIconEl.querySelector('use').getAttribute('xlink:href')).toContain('question-o');
    });

    it('renderts edit button', () => {
      const buttonEl = vm.$el.querySelector('button.btn-sidebar-action');
      expect(buttonEl).not.toBe(null);
      expect(buttonEl.innerText.trim()).toBe('Edit');
    });

    it('renders value container element', () => {
      expect(vm.$el.querySelector('.value .value-type-fixed')).not.toBe(null);
      expect(vm.$el.querySelector('.value .value-type-dynamic')).not.toBe(null);
    });

    it('renders fixed type date selection element', () => {
      const valueFixedEl = vm.$el.querySelector('.value .value-type-fixed');
      expect(valueFixedEl.querySelector('input[type="radio"]')).not.toBe(null);
      expect(valueFixedEl.innerText.trim()).toContain('Fixed:');
      expect(valueFixedEl.querySelector('.value-content').innerText.trim()).toContain('None');
    });

    it('renders dynamic type date selection element', () => {
      const valueDynamicEl = vm.$el.querySelector('.value abbr.value-type-dynamic');
      expect(valueDynamicEl.querySelector('input[type="radio"]')).not.toBe(null);
      expect(valueDynamicEl.innerText.trim()).toContain('From milestones:');
      expect(valueDynamicEl.querySelector('.value-content').innerText.trim()).toContain('None');
    });

    it('renders date warning icon when `isDateInvalid` prop is `true`', done => {
      vm.isDateInvalid = true;
      vm.selectedDateIsFixed = false;
      Vue.nextTick()
        .then(() => {
          const warningIconEl = vm.$el.querySelector('.date-warning-icon');
          expect(warningIconEl).not.toBe(null);
          expect(warningIconEl.getAttribute('tabindex')).toBe('0');
          expect(warningIconEl.querySelector('use').getAttribute('xlink:href')).toContain('warning');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
