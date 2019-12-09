import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import collapsedGroupedDatePicker from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';

describe('collapsedGroupedDatePicker', () => {
  let vm;
  beforeEach(() => {
    const CollapsedGroupedDatePicker = Vue.extend(collapsedGroupedDatePicker);
    vm = mountComponent(CollapsedGroupedDatePicker, {
      showToggleSidebar: true,
    });
  });

  describe('toggleCollapse events', () => {
    beforeEach(done => {
      jest.spyOn(vm, 'toggleSidebar').mockImplementation(() => {});
      vm.minDate = new Date('07/17/2016');
      Vue.nextTick(done);
    });

    it('should emit when collapsed-calendar-icon is clicked', () => {
      vm.$el.querySelector('.sidebar-collapsed-icon').click();

      expect(vm.toggleSidebar).toHaveBeenCalled();
    });
  });

  describe('minDate and maxDate', () => {
    beforeEach(done => {
      vm.minDate = new Date('07/17/2016');
      vm.maxDate = new Date('07/17/2017');
      Vue.nextTick(done);
    });

    it('should render both collapsed-calendar-icon', () => {
      const icons = vm.$el.querySelectorAll('.sidebar-collapsed-icon');

      expect(icons.length).toEqual(2);
      expect(icons[0].innerText.trim()).toEqual('Jul 17 2016');
      expect(icons[1].innerText.trim()).toEqual('Jul 17 2017');
    });
  });

  describe('minDate', () => {
    beforeEach(done => {
      vm.minDate = new Date('07/17/2016');
      Vue.nextTick(done);
    });

    it('should render minDate in collapsed-calendar-icon', () => {
      const icons = vm.$el.querySelectorAll('.sidebar-collapsed-icon');

      expect(icons.length).toEqual(1);
      expect(icons[0].innerText.trim()).toEqual('From Jul 17 2016');
    });
  });

  describe('maxDate', () => {
    beforeEach(done => {
      vm.maxDate = new Date('07/17/2017');
      Vue.nextTick(done);
    });

    it('should render maxDate in collapsed-calendar-icon', () => {
      const icons = vm.$el.querySelectorAll('.sidebar-collapsed-icon');

      expect(icons.length).toEqual(1);
      expect(icons[0].innerText.trim()).toEqual('Until Jul 17 2017');
    });
  });

  describe('no dates', () => {
    it('should render None', () => {
      const icons = vm.$el.querySelectorAll('.sidebar-collapsed-icon');

      expect(icons.length).toEqual(1);
      expect(icons[0].innerText.trim()).toEqual('None');
    });

    it('should have tooltip as `Start and due date`', () => {
      const icons = vm.$el.querySelectorAll('.sidebar-collapsed-icon');

      expect(icons[0].dataset.originalTitle).toBe('Start and due date');
    });
  });
});
