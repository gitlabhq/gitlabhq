import Vue from 'vue';

import GeoNodeHeaderComponent from 'ee/geo_nodes/components/geo_node_header.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockNode, mockNodeDetails } from '../mock_data';

const createComponent = ({
  node = Object.assign({}, mockNode),
  nodeDetails = Object.assign({}, mockNodeDetails),
  nodeDetailsLoading = false,
  nodeDetailsFailed = false,
}) => {
  const Component = Vue.extend(GeoNodeHeaderComponent);

  return mountComponent(Component, {
    node,
    nodeDetails,
    nodeDetailsLoading,
    nodeDetailsFailed,
  });
};

describe('GeoNodeHeader', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isNodeHTTP', () => {
      it('returns `true` when Node URL protocol is non-HTTPS', () => {
        expect(vm.isNodeHTTP).toBe(true);
      });

      it('returns `false` when Node URL protocol is HTTPS', (done) => {
        vm.node.url = 'https://127.0.0.1:3001/';
        Vue.nextTick()
          .then(() => {
            expect(vm.isNodeHTTP).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('showNodeStatusIcon', () => {
      it('returns `false` when Node details are still loading', (done) => {
        vm.nodeDetailsLoading = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.showNodeStatusIcon).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns `true` when Node details failed to load', (done) => {
        vm.nodeDetailsFailed = true;
        Vue.nextTick()
          .then(() => {
            expect(vm.showNodeStatusIcon).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns `true` when Node details loaded and Node URL is non-HTTPS', (done) => {
        vm.nodeDetailsLoading = false;
        vm.nodeDetailsFailed = false;
        vm.node.url = mockNode.url;
        Vue.nextTick()
          .then(() => {
            expect(vm.showNodeStatusIcon).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns `false` when Node details loaded and Node URL is HTTPS', (done) => {
        vm.node.url = 'https://127.0.0.1:3001/';
        Vue.nextTick()
          .then(() => {
            expect(vm.showNodeStatusIcon).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
