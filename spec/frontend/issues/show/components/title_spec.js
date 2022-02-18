import Vue, { nextTick } from 'vue';
import titleComponent from '~/issues/show/components/title.vue';
import eventHub from '~/issues/show/event_hub';
import Store from '~/issues/show/stores';

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

  it('updates page title when changing titleHtml', async () => {
    const spy = jest.spyOn(vm, 'setPageTitle');
    vm.titleHtml = 'test';

    await nextTick();
    expect(spy).toHaveBeenCalled();
  });

  it('animates title changes', async () => {
    vm.titleHtml = 'test';

    await nextTick();

    expect(vm.$el.querySelector('.title').classList).toContain('issue-realtime-pre-pulse');
    jest.runAllTimers();

    await nextTick();

    expect(vm.$el.querySelector('.title').classList).toContain('issue-realtime-trigger-pulse');
  });

  it('updates page title after changing title', async () => {
    vm.titleHtml = 'changed';
    vm.titleText = 'changed';

    await nextTick();
    expect(document.querySelector('title').textContent.trim()).toContain('changed');
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

    it('should trigger open.form event when clicked', async () => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      vm.showInlineEditButton = true;
      vm.canUpdate = true;

      await nextTick();
      vm.$el.querySelector('.btn-edit').click();

      expect(eventHub.$emit).toHaveBeenCalledWith('open.form');
    });
  });
});
