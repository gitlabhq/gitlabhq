import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AdminAccessSummary from '~/admin/users/components/user_type/admin_access_summary.vue';
import AccessSummary from '~/admin/users/components/user_type/access_summary.vue';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';

describe('AdminAccessSummary component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(AdminAccessSummary, {
      stubs: {
        AccessSummary: stubComponent(AccessSummary, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
    });
  };

  beforeEach(() => createWrapper());

  it('shows access summary', () => {
    expect(wrapper.findComponent(AccessSummary).exists()).toBe(true);
  });

  describe.each(['admin', 'group', 'settings'])('for %s section', (section) => {
    const findSlot = () => wrapper.findByTestId(`slot-${section}-content`);

    it('shows icon', () => {
      expect(findSlot().findComponent(GlIcon).props()).toMatchObject({
        name: 'check',
        variant: 'success',
      });
    });

    it('shows text', () => {
      expect(findSlot().text()).toBe('Full read and write access.');
    });
  });
});
