import Vue from 'vue';
import sidebarWeight from 'ee/sidebar/components/weight/sidebar_weight.vue';
import SidebarMediator from 'ee/sidebar/sidebar_mediator';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarStore from 'ee/sidebar/stores/sidebar_store';
import eventHub from '~/sidebar/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import Mock from './ee_mock_data';

describe('Sidebar Weight', function () {
  let vm;
  let sidebarMediator;
  let SidebarWeight;

  beforeEach(() => {
    SidebarWeight = Vue.extend(sidebarWeight);
    // Setup the stores, services, etc
    sidebarMediator = new SidebarMediator(Mock.mediator);
  });

  afterEach(() => {
    vm.$destroy();
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
  });

  it('calls the mediator updateWeight on event', () => {
    spyOn(SidebarMediator.prototype, 'updateWeight').and.returnValue(Promise.resolve());
    vm = mountComponent(SidebarWeight, {
      mediator: sidebarMediator,
    });

    eventHub.$emit('updateWeight');

    expect(SidebarMediator.prototype.updateWeight).toHaveBeenCalled();
  });
});
