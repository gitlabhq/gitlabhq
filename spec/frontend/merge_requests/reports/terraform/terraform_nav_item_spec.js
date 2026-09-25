import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TerraformNavItem from '~/merge_requests/reports/terraform/terraform_nav_item.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

describe('TerraformNavItem', () => {
  it('links to the terraform route with the injected loading state and icon', () => {
    const wrapper = shallowMountExtended(TerraformNavItem, {
      provide: { isTerraformLoading: true, statusIconName: 'warning' },
    });
    const item = wrapper.findComponent(ReportListItem);

    expect(item.text()).toBe('Terraform');
    expect(item.props()).toMatchObject({
      to: 'terraform',
      isLoading: true,
      statusIcon: 'warning',
    });
  });
});
