import Vue from 'vue';
import Vuex from 'vuex';
import component from 'ee/security_dashboard/components/security_dashboard_table.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Security Dashboard Table', () => {
  const vulnerabilities = [{ id: 0 }, { id: 1 }, { id: 2 }];
  let vm;
  let getters;
  let actions;

  beforeEach(() => {
    const Component = Vue.extend(component);
    getters = {
      vulnerabilities: () => vulnerabilities,
      pageInfo: () => null,
    };
    actions = {
      fetchVulnerabilities: jasmine.createSpy('fetchVulnerabilities'),
    };
    const store = new Vuex.Store({ actions, getters });
    vm = mountComponentWithStore(Component, { store });
  });

  afterEach(() => {
    actions.fetchVulnerabilities.calls.reset();
    vm.$destroy();
  });

  it('should dispatch a `fetchVulnerabilities` action on creation', () => {
    expect(actions.fetchVulnerabilities).toHaveBeenCalledTimes(1);
  });

  it('should render a row for each vulnerability', () => {
    expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(vulnerabilities.length);
  });
});
