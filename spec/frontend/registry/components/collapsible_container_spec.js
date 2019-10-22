import Vue from 'vue';
import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import collapsibleComponent from '~/registry/components/collapsible_container.vue';
import { repoPropsData } from '../mock_data';
import createFlash from '~/flash';
import * as getters from '~/registry/stores/getters';

jest.mock('~/flash.js');

const localVue = createLocalVue();

localVue.use(Vuex);

describe('collapsible registry container', () => {
  let wrapper;
  let store;

  const findDeleteBtn = w => w.find('.js-remove-repo');
  const findContainerImageTags = w => w.find('.container-image-tags');
  const findToggleRepos = w => w.findAll('.js-toggle-repo');

  const mountWithStore = config => mount(collapsibleComponent, { ...config, store, localVue });

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
    });

    const expectIsClosed = () => {
      const container = findContainerImageTags(wrapper);
      expect(container.exists()).toBe(false);
      expect(wrapper.vm.iconName).toEqual('angle-right');
    };

    it('should be closed by default', () => {
      expectIsClosed();
    });
    it('should be open when user clicks on closed repo', () => {
      const toggleRepos = findToggleRepos(wrapper);
      toggleRepos.at(0).trigger('click');
      const container = findContainerImageTags(wrapper);
      expect(container.exists()).toBe(true);
      expect(wrapper.vm.fetchList).toHaveBeenCalled();
    });
    it('should be closed when the user clicks on an opened repo', done => {
      const toggleRepos = findToggleRepos(wrapper);
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
      const deleteBtn = findDeleteBtn(wrapper);
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
      const deleteBtn = findDeleteBtn(wrapper);
      expect(deleteBtn.exists()).toBe(false);
    });
  });
});
