import { shallowMount } from '@vue/test-utils';
import App from '~/issuable_suggestions/components/app.vue';
import Suggestion from '~/issuable_suggestions/components/item.vue';

describe('Issuable suggestions app component', () => {
  let vm;

  function createComponent(search = 'search') {
    vm = shallowMount(App, {
      propsData: {
        search,
        projectPath: 'project',
      },
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('does not render with empty search', () => {
    createComponent('');

    expect(vm.isVisible()).toBe(false);
  });

  describe('with data', () => {
    let data;

    beforeEach(() => {
      data = { issues: [{ id: 1 }, { id: 2 }] };
    });

    it('renders component', () => {
      createComponent();
      vm.setData(data);

      expect(vm.isEmpty()).toBe(false);
    });

    it('does not render with empty search', () => {
      createComponent('');
      vm.setData(data);

      expect(vm.isVisible()).toBe(false);
    });

    it('does not render when loading', () => {
      createComponent();
      vm.setData({
        ...data,
        loading: 1,
      });

      expect(vm.isVisible()).toBe(false);
    });

    it('does not render with empty issues data', () => {
      createComponent();
      vm.setData({ issues: [] });

      expect(vm.isVisible()).toBe(false);
    });

    it('renders list of issues', () => {
      createComponent();
      vm.setData(data);

      expect(vm.findAll(Suggestion).length).toBe(2);
    });

    it('adds margin class to first item', () => {
      createComponent();
      vm.setData(data);

      expect(
        vm
          .findAll('li')
          .at(0)
          .is('.append-bottom-default'),
      ).toBe(true);
    });

    it('does not add margin class to last item', () => {
      createComponent();
      vm.setData(data);

      expect(
        vm
          .findAll('li')
          .at(1)
          .is('.append-bottom-default'),
      ).toBe(false);
    });
  });
});
