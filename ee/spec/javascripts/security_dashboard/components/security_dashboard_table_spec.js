import Vue from 'vue';
import MockAdapater from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import component from 'ee/security_dashboard/components/security_dashboard_table.vue';
import createStore from 'ee/security_dashboard/store';
import mockDataVulnerabilities from 'ee/security_dashboard/store/modules/vulnerabilities/mock_data_vulnerabilities.json';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import waitForPromises from 'spec/helpers/wait_for_promises';
import { resetStore } from '../helpers';

describe('Security Dashboard Table', () => {
  const Component = Vue.extend(component);
  const vulnerabilitiesEndpoint = '/vulnerabilitiesEndpoint.json';
  let store;
  let mock;
  let vm;

  beforeEach(() => {
    mock = new MockAdapater(axios);
    store = createStore();
    store.state.vulnerabilities.vulnerabilitiesEndpoint = vulnerabilitiesEndpoint;
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.dispatch('vulnerabilities/requestVulnerabilities');
      vm = mountComponentWithStore(Component, { store });
    });

    it('should render 10 skeleton rows in the table', () => {
      expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(10);
    });
  });

  describe('with success result', () => {
    beforeEach(() => {
      mock.onGet(vulnerabilitiesEndpoint).replyOnce(200, mockDataVulnerabilities);
      vm = mountComponentWithStore(Component, { store });
    });

    it('should render a row for each vulnerability', done => {
      waitForPromises()
        .then(() => {
          expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(
            mockDataVulnerabilities.length,
          );
          done();
        })
        .catch(done.fail);
    });
  });
});
