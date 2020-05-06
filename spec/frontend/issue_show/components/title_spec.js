import Vue from 'vue';
import Store from '~/issue_show/stores';
import titleComponent from '~/issue_show/components/title.vue';
import eventHub from '~/issue_show/event_hub';

describe('Title component', () => {
  let vm;
  beforeEach(() => {
    setFixtures(`<title />`);

    const Component = Vue.extend(titleComponent);
    const store = new Store({
      titleHtml: '',
      descriptionHtml: '',
      issuableRef: '',
    });
    vm = new Component({
      propsData: {
        issuableRef: '#1',
        titleHtml: 'Testing <img />',
        titleText: 'Testing',
        showForm: false,
        formState: store.formState,
      },
    }).$mount();
  });

  it('renders title HTML', () => {
    expect(vm.$el.querySelector('.title').innerHTML.trim()).toBe('Testing <img>');
  });

  it('updates page title when changing titleHtml', () => {
    const spy = jest.spyOn(vm, 'setPageTitle');
    vm.titleHtml = 'test';

    return vm.$nextTick().then(() => {
      expect(spy).toHaveBeenCalled();
    });
  });

  it('animates title changes', () => {
    vm.titleHtml = 'test';
    return vm
      .$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.title').classList).toContain('issue-realtime-pre-pulse');
        jest.runAllTimers();
        return vm.$nextTick();
      })
      .then(() => {
        expect(vm.$el.querySelector('.title').classList).toContain('issue-realtime-trigger-pulse');
      });
  });

  it('updates page title after changing title', () => {
    vm.titleHtml = 'changed';
    vm.titleText = 'changed';

    return vm.$nextTick().then(() => {
      expect(document.querySelector('title').textContent.trim()).toContain('changed');
    });
  });

  describe('inline edit button', () => {
    it('should not show by default', () => {
      expect(vm.$el.querySelector('.btn-edit')).toBeNull();
    });

    it('should not show if canUpdate is false', () => {
      vm.showInlineEditButton = true;
      vm.canUpdate = false;

      expect(vm.$el.querySelector('.btn-edit')).toBeNull();
    });

    it('should show if showInlineEditButton and canUpdate', () => {
      vm.showInlineEditButton = true;
      vm.canUpdate = true;

      expect(vm.$el.querySelector('.btn-edit')).toBeDefined();
    });

    it('should trigger open.form event when clicked', () => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      vm.showInlineEditButton = true;
      vm.canUpdate = true;

      Vue.nextTick(() => {
        vm.$el.querySelector('.btn-edit').click();

        expect(eventHub.$emit).toHaveBeenCalledWith('open.form');
      });
    });
  });
});
