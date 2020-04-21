import { mount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import stubChildren from 'helpers/stub_children';
import AlertManagementList from '~/alert_management/components/alert_management_list.vue';

describe('AlertManagementList', () => {
  let wrapper;

  function mountComponent({ stubs = {} } = {}) {
    wrapper = mount(AlertManagementList, {
      propsData: {
        indexPath: '/path',
        enableAlertManagementPath: '/link',
        emptyAlertSvgPath: 'illustration/path',
      },
      stubs: {
        ...stubChildren(AlertManagementList),
        ...stubs,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('alert management feature renders empty state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });
});
