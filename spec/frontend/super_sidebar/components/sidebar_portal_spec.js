import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';

describe('SidebarPortal', () => {
  let targetWrapper;

  const Target = {
    components: { SidebarPortalTarget },
    props: ['show'],
    template: '<sidebar-portal-target v-if="show" />',
  };

  const Source = {
    components: { SidebarPortal },
    template: '<sidebar-portal><br data-testid="test"></sidebar-portal>',
  };

  const mountSource = () => {
    mount(Source);
  };

  const mountTarget = ({ show = true } = {}) => {
    targetWrapper = mount(Target, {
      propsData: { show },
      attachTo: document.body,
    });
  };

  const findTestContent = () => targetWrapper.find('[data-testid="test"]');

  it('renders content into the target', async () => {
    mountTarget();
    await nextTick();

    mountSource();
    await nextTick();

    expect(findTestContent().exists()).toBe(true);
  });

  it('waits for target to be available before rendering', async () => {
    mountSource();
    await nextTick();

    mountTarget();
    await nextTick();

    expect(findTestContent().exists()).toBe(true);
  });

  it('supports conditional rendering of target', async () => {
    mountTarget({ show: false });
    await nextTick();

    mountSource();
    await nextTick();

    expect(findTestContent().exists()).toBe(false);

    await targetWrapper.setProps({ show: true });
    expect(findTestContent().exists()).toBe(true);

    await targetWrapper.setProps({ show: false });
    expect(findTestContent().exists()).toBe(false);
  });
});
