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
    });

  beforeEach(() => {
    createFlash.mockClear();
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

    it('should be open when user clicks on closed repo', () => {
      const toggleRepos = findToggleRepos();
      toggleRepos.at(0).trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        const container = findContainerImageTags();
        expect(container.exists()).toBe(true);
        expect(wrapper.vm.fetchList).toHaveBeenCalled();
      });
    });

    it('should be closed when the user clicks on an opened repo', () => {
      const toggleRepos = findToggleRepos();
      toggleRepos.at(0).trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        toggleRepos.at(0).trigger('click');
        wrapper.vm.$nextTick(() => {
          expectIsClosed();
        });
      });
    });
  });

  describe('delete repo', () => {
    beforeEach(() => {
      const deleteItem = jest.fn().mockResolvedValue();
      const fetchRepos = jest.fn().mockResolvedValue();
      wrapper.setMethods({ deleteItem, fetchRepos });
    });

    it('should be possible to delete a repo', () => {
      const deleteBtn = findDeleteBtn();
      expect(deleteBtn.exists()).toBe(true);
    });

    it('should call deleteItem when confirming deletion', () => {
      wrapper.vm.handleDeleteRepository();
      expect(wrapper.vm.deleteItem).toHaveBeenCalledWith(wrapper.vm.repo);
    });

    it('should show a flash with a success notice', () =>
      wrapper.vm.handleDeleteRepository().then(() => {
        expect(wrapper.vm.deleteImageConfirmationMessage).toContain(wrapper.vm.repo.name);
        expect(createFlash).toHaveBeenCalledWith(
          wrapper.vm.deleteImageConfirmationMessage,
          'notice',
        );
      }));

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
