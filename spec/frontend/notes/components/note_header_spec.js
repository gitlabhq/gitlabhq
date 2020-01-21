import Vue from 'vue';
import noteHeader from '~/notes/components/note_header.vue';
import createStore from '~/notes/stores';

describe('note_header component', () => {
  let store;
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(noteHeader);
    store = createStore();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('individual note', () => {
    beforeEach(() => {
      vm = new Component({
        store,
        propsData: {
          actionText: 'commented',
          actionTextHtml: '',
          author: {
            avatar_url: null,
            id: 1,
            name: 'Root',
            path: '/root',
            state: 'active',
            username: 'root',
          },
          createdAt: '2017-08-02T10:51:58.559Z',
          includeToggle: false,
          noteId: '1394',
          expanded: true,
        },
      }).$mount();
    });

    it('should render user information', () => {
      expect(vm.$el.querySelector('.note-header-author-name').textContent.trim()).toEqual('Root');
      expect(vm.$el.querySelector('.note-header-info a').getAttribute('href')).toEqual('/root');
      expect(vm.$el.querySelector('.note-header-info a').dataset.userId).toEqual('1');
      expect(vm.$el.querySelector('.note-header-info a').dataset.username).toEqual('root');
      expect(vm.$el.querySelector('.note-header-info a').classList).toContain('js-user-link');
    });

    it('should render timestamp link', () => {
      expect(vm.$el.querySelector('a[href="#note_1394"]')).toBeDefined();
    });

    it('should not render user information when prop `author` is empty object', done => {
      vm.author = {};
      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.note-header-author-name')).toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('discussion', () => {
    beforeEach(() => {
      vm = new Component({
        store,
        propsData: {
          actionText: 'started a discussion',
          actionTextHtml: '',
          author: {
            avatar_url: null,
            id: 1,
            name: 'Root',
            path: '/root',
            state: 'active',
            username: 'root',
          },
          createdAt: '2017-08-02T10:51:58.559Z',
          includeToggle: true,
          noteId: '1395',
          expanded: true,
        },
      }).$mount();
    });

    it('should render toggle button', () => {
      expect(vm.$el.querySelector('.js-vue-toggle-button')).toBeDefined();
    });

    it('emits toggle event on click', done => {
      jest.spyOn(vm, '$emit').mockImplementation(() => {});

      vm.$el.querySelector('.js-vue-toggle-button').click();

      Vue.nextTick(() => {
        expect(vm.$emit).toHaveBeenCalledWith('toggleHandler');
        done();
      });
    });

    it('renders up arrow when open', done => {
      vm.expanded = true;

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.js-vue-toggle-button i').classList).toContain(
          'fa-chevron-up',
        );
        done();
      });
    });

    it('renders down arrow when closed', done => {
      vm.expanded = false;

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.js-vue-toggle-button i').classList).toContain(
          'fa-chevron-down',
        );
        done();
      });
    });
  });
});
