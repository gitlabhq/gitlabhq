import Vue from 'vue';
import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import createFlash from '~/flash';
import Tracking from '~/tracking';
import collapsibleComponent from '~/registry/list/components/collapsible_container.vue';
import * as getters from '~/registry/list/stores/getters';
import { repoPropsData } from '../mock_data';

jest.mock('~/flash.js');

const localVue = createLocalVue();

localVue.use(Vuex);

describe('collapsible registry container', () => {
  let wrapper;
  let store;

  const findDeleteBtn = () => wrapper.find('.js-remove-repo');
  const findContainerImageTags = () => wrapper.find('.container-image-tags');
  const findToggleRepos = () => wrapper.findAll('.js-toggle-repo');
  const findDeleteModal = () => wrapper.find({ ref: 'deleteModal' });

  const mountWithStore = config =>
    mount(collapsibleComponent, {
      ...config,
      store,
      localVue,
      attachToDocument: true,
      sync: false,
    });

  beforeEach(() => {
    createFlash.mockClear();
    // This is needed due to  console.error called by vue to emit a warning that stop the tests
    // see  https://github.com/vuejs/vue-test-utils/issues/532
    Vue.config.silent = true;
    store = new Vuex.Store({
      state: {
        isDeleteDisabled: false,
      },
      getters,
    });

    wrapper = mountWithStore({
      propsData: {
        repo: repoPropsData,
      },
    });
  });

  afterEach(() => {
    Vue.config.silent = false;
    wrapper.destroy();
  });

  describe('toggle', () => {
    beforeEach(() => {
      const fetchList = jest.fn();
      wrapper.setMethods({ fetchList });
      return wrapper.vm.$nextTick();
    });

    const expectIsClosed = () => {
      const container = findContainerImageTags();
      expect(container.exists()).toBe(false);
      expect(wrapper.vm.iconName).toEqual('angle-right');
    };

    it('should be closed by default', () => {
      expectIsClosed();
    });

    it('should be open when user clicks on closed repo', done => {
      const toggleRepos = findToggleRepos();
      toggleRepos.at(0).trigger('click');
      Vue.nextTick(() => {
        const container = findContainerImageTags();
        expect(container.exists()).toBe(true);
        expect(wrapper.vm.fetchList).toHaveBeenCalled();
        done();
      });
    });

    it('should be closed when the user clicks on an opened repo', done => {
      const toggleRepos = findToggleRepos();
      toggleRepos.at(0).trigger('click');
      Vue.nextTick(() => {
        toggleRepos.at(0).trigger('click');
        Vue.nextTick(() => {
          expectIsClosed();
          done();
        });
      });
    });
  });

  describe('delete repo', () => {
    it('should be possible to delete a repo', () => {
      const deleteBtn = findDeleteBtn();
      expect(deleteBtn.exists()).toBe(true);
    });

    it('should call deleteItem when confirming deletion', () => {
      const deleteItem = jest.fn().mockResolvedValue();
      const fetchRepos = jest.fn().mockResolvedValue();
      wrapper.setMethods({ deleteItem, fetchRepos });
      wrapper.vm.handleDeleteRepository();
      expect(wrapper.vm.deleteItem).toHaveBeenCalledWith(wrapper.vm.repo);
    });

    it('should show an error when there is API error', () => {
      const deleteItem = jest.fn().mockRejectedValue('error');
      wrapper.setMethods({ deleteItem });
      return wrapper.vm.handleDeleteRepository().then(() => {
        expect(createFlash).toHaveBeenCalled();
      });
    });
  });

  describe('disabled delete', () => {
    beforeEach(() => {
      store = new Vuex.Store({
        state: {
          isDeleteDisabled: true,
        },
        getters,
      });
      wrapper = mountWithStore({
        propsData: {
          repo: repoPropsData,
        },
      });
    });

    it('should not render delete button', () => {
      const deleteBtn = findDeleteBtn();
      expect(deleteBtn.exists()).toBe(false);
    });
  });

  describe('tracking', () => {
    const testTrackingCall = action => {
      expect(Tracking.event).toHaveBeenCalledWith(undefined, action, {
        label: 'registry_repository_delete',
      });
    };

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      wrapper.vm.deleteItem = jest.fn().mockResolvedValue();
      wrapper.vm.fetchRepos = jest.fn();
    });

    it('send an event when delete button is clicked', () => {
      const deleteBtn = findDeleteBtn();
      deleteBtn.trigger('click');
      testTrackingCall('click_button');
    });
    it('send an event when cancel is pressed on modal', () => {
      const deleteModal = findDeleteModal();
      deleteModal.vm.$emit('cancel');
      testTrackingCall('cancel_delete');
    });
    it('send an event when confirm is clicked on modal', () => {
      const deleteModal = findDeleteModal();
      deleteModal.vm.$emit('ok');

      testTrackingCall('confirm_delete');
    });
  });
});
