import Vue from 'vue';
import _ from 'underscore';
import Cookies from 'js-cookie';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import epicSidebar from 'ee/epics/sidebar/components/sidebar_app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { props } from 'ee_spec/epics/epic_show/mock_data';

describe('epicSidebar', () => {
  let vm;
  let originalCookieState;
  let EpicSidebar;
  const {
    epicId,
    updateEndpoint,
    labelsPath,
    labelsWebUrl,
    epicsWebUrl,
    labels,
    participants,
    subscribed,
    toggleSubscriptionPath,
    todoExists,
    todoPath,
    todoDeletePath,
    startDateIsFixed,
    startDateFixed,
    startDateFromMilestones,
    dueDateIsFixed,
    dueDateFixed,
    dueDateFromMilestones,
    startDateSourcingMilestoneTitle,
    dueDateSourcingMilestoneTitle,
  } = props;

  const defaultPropsData = {
    epicId,
    endpoint: gl.TEST_HOST,
    initialLabels: labels,
    initialParticipants: participants,
    initialSubscribed: subscribed,
    initialTodoExists: todoExists,
    initialStartDateIsFixed: startDateIsFixed,
    initialStartDateFixed: startDateFixed,
    startDateFromMilestones,
    initialDueDateIsFixed: dueDateIsFixed,
    initialDueDateFixed: dueDateFixed,
    dueDateFromMilestones,
    updatePath: updateEndpoint,
    startDateSourcingMilestoneTitle,
    dueDateSourcingMilestoneTitle,
    toggleSubscriptionPath,
    labelsPath,
    labelsWebUrl,
    epicsWebUrl,
    todoPath,
    todoDeletePath,
  };

  beforeEach(() => {
    setFixtures(`
      <div class="page-with-contextual-sidebar right-sidebar-expanded">
        <div id="epic-sidebar"></div>
      </div>
    `);

    originalCookieState = Cookies.get('collapsed_gutter');
    Cookies.set('collapsed_gutter', null);
    EpicSidebar = Vue.extend(epicSidebar);
    vm = mountComponent(EpicSidebar, defaultPropsData, '#epic-sidebar');
  });

  afterEach(() => {
    Cookies.set('collapsed_gutter', originalCookieState);
  });

  it('should render right-sidebar-expanded class when not collapsed', () => {
    expect(vm.$el.classList.contains('right-sidebar-expanded')).toEqual(true);
  });

  it('should render both sidebar-date-picker', () => {
    vm = mountComponent(EpicSidebar, Object.assign({}, defaultPropsData, {
      initialStartDate: '2017-01-01',
      initialEndDate: '2018-01-01',
    }));

    const startDatePicker = vm.$el.querySelector('.block.start-date');
    const endDatePicker = vm.$el.querySelector('.block.end-date');
    expect(startDatePicker.querySelector('.value-type-fixed .value-content').innerText.trim()).toEqual('Jan 1, 2017');
    expect(endDatePicker.querySelector('.value-type-fixed .value-content').innerText.trim()).toEqual('Jan 1, 2018');
  });

  describe('computed prop', () => {
    const getComponent = (customPropsData = {
      initialStartDateIsFixed: true,
      startDateFromMilestones: '2018-01-01',
      initialStartDate: '2017-01-01',
      initialDueDateIsFixed: true,
      dueDateFromMilestones: '2018-11-31',
      initialEndDate: '2018-01-01',
    }) => new EpicSidebar({
      propsData: Object.assign({}, defaultPropsData, customPropsData),
    });

    describe('isDateValid', () => {
      it('returns true when fixed start and end dates are valid', () => {
        const component = getComponent();
        expect(component.isDateValid).toBe(true);
      });

      it('returns false when fixed start and end dates are invalid', () => {
        const component = getComponent({
          initialStartDate: '2018-01-01',
          initialEndDate: '2017-01-01',
        });
        expect(component.isDateValid).toBe(false);
      });

      it('returns true when milestone start date and fixed end date is valid', () => {
        const component = getComponent({
          initialStartDateIsFixed: false,
          initialEndDate: '2018-11-31',
        });
        expect(component.isDateValid).toBe(true);
      });

      it('returns true when milestone start date and milestone end date is valid', () => {
        const component = getComponent({
          initialStartDateIsFixed: false,
          initialDueDateIsFixed: false,
        });
        expect(component.isDateValid).toBe(true);
      });
    });
  });

  describe('when collapsed', () => {
    beforeEach(() => {
      Cookies.set('collapsed_gutter', 'true');
      vm = mountComponent(EpicSidebar, Object.assign({}, defaultPropsData, { initialStartDate: '2017-01-01' }));
    });

    it('should render right-sidebar-collapsed class', () => {
      expect(vm.$el.classList.contains('right-sidebar-collapsed')).toEqual(true);
    });

    it('should render collapsed grouped date picker', () => {
      expect(vm.$el.querySelector('.sidebar-grouped-item .sidebar-collapsed-icon span').innerText.trim()).toEqual('From Jan 1 2017');
    });

    it('should render collapsed labels picker', () => {
      expect(vm.$el.querySelector('.js-labels-block .sidebar-collapsed-icon span').innerText.trim()).toEqual('1');
    });
  });

  describe('getDateFromMilestonesTooltip', () => {
    it('returns tooltip string for milestone', () => {
      expect(vm.getDateFromMilestonesTooltip('start')).toBe('To schedule your epic\'s start date based on milestones, assign a milestone with a due date to any issue in the epic.');
    });
  });

  describe('toggleSidebar', () => {
    it('should toggle collapsed_gutter cookie', () => {
      expect(vm.$el.classList.contains('right-sidebar-expanded')).toEqual(true);
      vm.$el.querySelector('.gutter-toggle').click();

      expect(Cookies.get('collapsed_gutter')).toEqual('true');
    });

    it('should toggle contentContainer css class', () => {
      const contentContainer = document.querySelector('.page-with-contextual-sidebar');
      expect(contentContainer.classList.contains('right-sidebar-expanded')).toEqual(true);
      expect(contentContainer.classList.contains('right-sidebar-collapsed')).toEqual(false);

      vm.$el.querySelector('.gutter-toggle').click();
      expect(contentContainer.classList.contains('right-sidebar-expanded')).toEqual(false);
      expect(contentContainer.classList.contains('right-sidebar-collapsed')).toEqual(true);
    });
  });

  describe('saveDate', () => {
    let component;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onPut(gl.TEST_HOST).reply(() => [200, JSON.stringify({})]);

      component = new EpicSidebar({
        propsData: defaultPropsData,
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('should save startDate', (done) => {
      const date = '2017-01-01';
      expect(component.store.startDate).toBeUndefined();
      component.saveStartDate(date)
        .then(() => {
          expect(component.store.startDate).toEqual(date);
          done();
        })
        .catch(done.fail);
    });

    it('should save endDate', (done) => {
      const date = '2017-01-01';
      expect(component.store.endDate).toBeUndefined();
      component.saveEndDate(date)
        .then(() => {
          expect(component.store.endDate).toEqual(date);
          done();
        })
        .catch(done.fail);
    });

    it('should change start date type', (done) => {
      spyOn(component.service, 'updateStartDate').and.callThrough();
      const dateValue = '2017-01-01';
      component.saveDate('start', dateValue, false);
      Vue.nextTick()
        .then(() => {
          expect(component.service.updateStartDate).toHaveBeenCalledWith({
            dateValue,
            isFixed: false,
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('should change end date type', (done) => {
      spyOn(component.service, 'updateEndDate').and.callThrough();
      const dateValue = '2017-01-01';
      component.saveDate('end', dateValue, false);
      Vue.nextTick()
        .then(() => {
          expect(component.service.updateEndDate).toHaveBeenCalledWith({
            dateValue,
            isFixed: false,
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('handleLabelClick', () => {
    const label = {
      id: 1,
      title: 'Foo',
      color: ['#BADA55'],
      text_color: '#FFFFFF',
    };

    it('initializes `epicContext.labels` as empty array when `label.isAny` is `true`', () => {
      const labelIsAny = { isAny: true };
      vm.handleLabelClick(labelIsAny);
      expect(Array.isArray(vm.epicContext.labels)).toBe(true);
      expect(vm.epicContext.labels.length).toBe(0);
    });

    it('adds provided `label` to epicContext.labels', () => {
      vm.handleLabelClick(label);
      // epicContext.labels gets initialized with initialLabels, hence
      // newly insert label will be at second position (index `1`)
      expect(vm.epicContext.labels.length).toBe(2);
      expect(vm.epicContext.labels[1].id).toBe(label.id);
      vm.handleLabelClick(label);
    });

    it('filters epicContext.labels to exclude provided `label` if it is already present in `epicContext.labels`', () => {
      vm.handleLabelClick(label); // Select
      vm.handleLabelClick(label); // Un-select
      expect(vm.epicContext.labels.length).toBe(1);
      expect(vm.epicContext.labels[0].id).toBe(labels[0].id);
    });
  });

  describe('handleDropdownClose', () => {
    it('calls toggleSidebar when `autoExpanded` prop is true', () => {
      spyOn(vm, 'toggleSidebar');
      vm.autoExpanded = true;
      vm.handleDropdownClose();

      expect(vm.autoExpanded).toBe(false);
      expect(vm.toggleSidebar).toHaveBeenCalled();
    });

    it('does not call toggleSidebar when `autoExpanded` prop is false', () => {
      spyOn(vm, 'toggleSidebar');
      vm.autoExpanded = false;
      vm.handleDropdownClose();

      expect(vm.autoExpanded).toBe(false);
      expect(vm.toggleSidebar).not.toHaveBeenCalled();
    });
  });

  describe('handleToggleTodo', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      setFixtures('<div class="flash-container"></div>');
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
      mock.restore();
    });

    it('calls `addTodo` on service object when `todoExists` prop is `false`', () => {
      spyOn(vm.service, 'addTodo').and.callThrough();
      vm.store.setTodoExists(false);
      expect(vm.savingTodoAction).toBe(false);
      vm.handleToggleTodo();
      expect(vm.savingTodoAction).toBe(true);
      expect(vm.service.addTodo).toHaveBeenCalledWith(epicId);
    });

    it('calls `addTodo` on service and sets response on store when request is successful', done => {
      mock.onPost(gl.TEST_HOST).reply(200, {
        delete_path: '/foo/bar',
        count: 1,
      });
      spyOn(vm.service, 'addTodo').and.callThrough();
      vm.store.setTodoExists(false);

      vm.handleToggleTodo();
      setTimeout(() => {
        expect(vm.savingTodoAction).toBe(false);
        expect(vm.store.todoDeletePath).toBe('/foo/bar');
        expect(vm.store.todoExists).toBe(true);
        done();
      }, 0);
    });

    it('calls `addTodo` on service and shows Flash error when request is unsuccessful', done => {
      mock.onPost(gl.TEST_HOST).reply(500, {});
      spyOn(vm.service, 'addTodo').and.callThrough();
      vm.store.setTodoExists(false);

      vm.handleToggleTodo();
      setTimeout(() => {
        expect(vm.savingTodoAction).toBe(false);
        expect(document.querySelector('.flash-text').innerText.trim()).toBe('There was an error adding a todo.');
        done();
      }, 0);
    });

    it('calls `deleteTodo` on service object when `todoExists` prop is `true`', () => {
      spyOn(vm.service, 'deleteTodo').and.callThrough();
      vm.store.setTodoExists(true);
      expect(vm.savingTodoAction).toBe(false);
      vm.handleToggleTodo();
      expect(vm.savingTodoAction).toBe(true);
      expect(vm.service.deleteTodo).toHaveBeenCalledWith(gl.TEST_HOST);
    });

    it('calls `deleteTodo` on service and sets response on store when request is successful', done => {
      mock.onDelete(gl.TEST_HOST).reply(200, {
        count: 1,
      });
      spyOn(vm.service, 'deleteTodo').and.callThrough();
      vm.store.setTodoExists(true);

      vm.handleToggleTodo();
      setTimeout(() => {
        expect(vm.savingTodoAction).toBe(false);
        expect(vm.store.todoExists).toBe(false);
        done();
      }, 0);
    });

    it('calls `deleteTodo` on service and shows Flash error when request is unsuccessful', done => {
      mock.onDelete(gl.TEST_HOST).reply(500, {});
      spyOn(vm.service, 'deleteTodo').and.callThrough();
      vm.store.setTodoExists(true);

      vm.handleToggleTodo();
      setTimeout(() => {
        expect(vm.savingTodoAction).toBe(false);
        expect(document.querySelector('.flash-text').innerText.trim()).toBe('There was an error deleting the todo.');
        done();
      }, 0);
    });
  });

  describe('saveDate error', () => {
    let interceptor;
    let component;

    beforeEach(() => {
      interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify({}), {
          status: 500,
        }));
      };
      Vue.http.interceptors.push(interceptor);
      component = new EpicSidebar({
        propsData: defaultPropsData,
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should handle errors gracefully', (done) => {
      const date = '2017-01-01';
      expect(component.store.startDate).toBeUndefined();
      component.saveDate('start', date)
        .then(() => {
          expect(component.store.startDate).toBeUndefined();
          done();
        })
        .catch(done.fail);
    });
  });
});
